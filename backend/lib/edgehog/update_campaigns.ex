#
# This file is part of Edgehog.
#
# Copyright 2023 SECO Mind Srl
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0
#

defmodule Edgehog.UpdateCampaigns do
  @moduledoc """
  The UpdateCampaigns context.
  """

  import Ecto.Query, warn: false
  alias Edgehog.Repo

  alias Ecto.Multi
  alias Edgehog.UpdateCampaigns.UpdateChannel

  @doc """
  Preloads the default associations for an UpdateChannel or a list of UpdateChannels
  """
  def preload_defaults_for_update_channel(channel_or_channels, opts \\ []) do
    Repo.preload(channel_or_channels, [:target_groups], opts)
  end

  @doc """
  Returns the list of update_channels.

  ## Examples

      iex> list_update_channels()
      [%UpdateChannel{}, ...]

  """
  def list_update_channels do
    Repo.all(UpdateChannel)
    |> preload_defaults_for_update_channel()
  end

  @doc """
  Fetches a single update_channel.

  Returns `{:error, :not_found}` if the Update channel does not exist.

  ## Examples

      iex> fetch_update_channel(123)
      {:ok, %UpdateChannel{}}

      iex> fetch_update_channel(456)
      {:error, :not_found}

  """
  def fetch_update_channel(id) do
    case Repo.get(UpdateChannel, id) do
      nil ->
        {:error, :not_found}

      %UpdateChannel{} = update_channel ->
        {:ok, preload_defaults_for_update_channel(update_channel)}
    end
  end

  @doc """
  Creates a update_channel.

  ## Examples

      iex> create_update_channel(%{field: value})
      {:ok, %UpdateChannel{}}

      iex> create_update_channel(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_update_channel(attrs \\ %{}) do
    Multi.new()
    |> Multi.insert(:update_channel, UpdateChannel.create_changeset(%UpdateChannel{}, attrs))
    |> Multi.merge(fn %{update_channel: update_channel} ->
      assign_and_check_groups_multi(update_channel)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{update_channel: update_channel}} ->
        update_channel =
          %{update_channel | target_group_ids: nil}
          |> preload_defaults_for_update_channel()

        {:ok, update_channel}

      {:error, _failed_operation, failed_value, _changes_so_far} ->
        {:error, failed_value}
    end
  end

  @doc """
  Updates a update_channel.

  ## Examples

      iex> update_update_channel(update_channel, %{field: new_value})
      {:ok, %UpdateChannel{}}

      iex> update_update_channel(update_channel, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_update_channel(%UpdateChannel{} = update_channel, attrs) do
    Multi.new()
    |> Multi.update(:update_channel, UpdateChannel.changeset(update_channel, attrs))
    |> Multi.merge(fn %{update_channel: update_channel} ->
      maybe_update_groups_multi(update_channel)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{update_channel: update_channel}} ->
        # Force the preload since groups could have changed
        update_channel =
          %{update_channel | target_group_ids: nil}
          |> preload_defaults_for_update_channel(force: true)

        {:ok, update_channel}

      {:error, _failed_operation, failed_value, _changes_so_far} ->
        {:error, failed_value}
    end
  end

  defp maybe_update_groups_multi(%UpdateChannel{target_group_ids: nil}) do
    Multi.new()
  end

  defp maybe_update_groups_multi(%UpdateChannel{} = update_channel) do
    Multi.new()
    |> Multi.update_all(:unassign_groups, unassign_groups_query(update_channel), [])
    |> Multi.merge(fn _changes ->
      assign_and_check_groups_multi(update_channel)
    end)
  end

  defp assign_and_check_groups_multi(%UpdateChannel{} = update_channel) do
    Multi.new()
    |> Multi.update_all(:assign_groups, assign_groups_query(update_channel), [])
    |> Multi.run(:check_group_conflict, fn _repo, %{assign_groups: {update_count, _}} ->
      if length(update_channel.target_group_ids) != update_count do
        build_conflicting_or_non_existing_groups_error(update_channel)
      else
        {:ok, nil}
      end
    end)
  end

  defp unassign_groups_query(%UpdateChannel{} = update_channel) do
    from t in "device_groups",
      where: t.update_channel_id == ^update_channel.id,
      update: [set: [update_channel_id: nil]]
  end

  defp assign_groups_query(%UpdateChannel{} = update_channel) do
    from t in "device_groups",
      where: t.id in ^update_channel.target_group_ids and is_nil(t.update_channel_id),
      update: [set: [update_channel_id: ^update_channel.id]]
  end

  defp build_conflicting_or_non_existing_groups_error(%UpdateChannel{} = update_channel) do
    conflicting_group_ids =
      from(t in "device_groups",
        where: t.id in ^update_channel.target_group_ids and not is_nil(t.update_channel_id),
        select: t.id
      )
      |> Repo.all()

    assigned_group_ids =
      from(t in "device_groups",
        where: t.update_channel_id == ^update_channel.id,
        select: t.id
      )
      |> Repo.all()

    non_existing_group_ids =
      MapSet.new(update_channel.target_group_ids)
      |> MapSet.difference(MapSet.new(conflicting_group_ids ++ assigned_group_ids))
      |> MapSet.to_list()

    error_changeset =
      update_channel
      |> change_update_channel()
      |> add_conflicting_groups_errors(conflicting_group_ids)
      |> add_non_existing_groups_errors(non_existing_group_ids)

    {:error, error_changeset}
  end

  defp add_conflicting_groups_errors(%Ecto.Changeset{} = changeset, conflicting_group_ids)
       when is_list(conflicting_group_ids) do
    Enum.reduce(conflicting_group_ids, changeset, fn conflicting_id, changeset ->
      message = "contains %{id}, which is already assigned to another update channel"
      Ecto.Changeset.add_error(changeset, :target_group_ids, message, id: conflicting_id)
    end)
  end

  defp add_non_existing_groups_errors(%Ecto.Changeset{} = changeset, non_existing_group_ids)
       when is_list(non_existing_group_ids) do
    Enum.reduce(non_existing_group_ids, changeset, fn non_existing_id, changeset ->
      message = "contains %{id}, which is not an existing target group"
      Ecto.Changeset.add_error(changeset, :target_group_ids, message, id: non_existing_id)
    end)
  end

  @doc """
  Deletes a update_channel.

  ## Examples

      iex> delete_update_channel(update_channel)
      {:ok, %UpdateChannel{}}

      iex> delete_update_channel(update_channel)
      {:error, %Ecto.Changeset{}}

  """
  def delete_update_channel(%UpdateChannel{} = update_channel) do
    Multi.new()
    |> Multi.update_all(:unassign_groups, unassign_groups_query(update_channel), [])
    |> Multi.delete(:update_channel, update_channel)
    |> Repo.transaction()
    |> case do
      {:ok, %{update_channel: update_channel}} ->
        {:ok, preload_defaults_for_update_channel(update_channel)}

      {:error, _failed_operation, failed_value, _changes_so_far} ->
        {:error, failed_value}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking update_channel changes.

  ## Examples

      iex> change_update_channel(update_channel)
      %Ecto.Changeset{data: %UpdateChannel{}}

  """
  def change_update_channel(%UpdateChannel{} = update_channel, attrs \\ %{}) do
    UpdateChannel.changeset(update_channel, attrs)
  end

  @doc """
  Returns a `device_group_id -> update_channel` map for the passed DeviceGroup ids.

  This allows retrieving the update channels for a list of device groups by doing one query

  ## Examples

  iex> get_update_channels_for_device_group_ids(device_ids)
  %{1 => %UpdateChannel{}, 2 => nil, 3 => ...}
  """
  def get_update_channels_for_device_group_ids(device_group_ids) when is_list(device_group_ids) do
    query =
      from dg in "device_groups",
        where: dg.id in ^device_group_ids,
        left_join: uc in UpdateChannel,
        on: dg.update_channel_id == uc.id,
        select: {dg.id, uc}

    Repo.all(query)
    |> Map.new()
  end
end
