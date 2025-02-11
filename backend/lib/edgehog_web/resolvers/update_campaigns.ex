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

defmodule EdgehogWeb.Resolvers.UpdateCampaigns do
  alias Edgehog.UpdateCampaigns
  alias Edgehog.UpdateCampaigns.UpdateChannel
  import Absinthe.Resolution.Helpers, only: [batch: 3]

  def find_update_channel(args, _resolution) do
    UpdateCampaigns.fetch_update_channel(args.id)
  end

  def list_update_channels(_args, _resolution) do
    update_channels = UpdateCampaigns.list_update_channels()

    {:ok, update_channels}
  end

  def create_update_channel(args, _resolution) do
    with {:ok, %UpdateChannel{} = update_channel} <- UpdateCampaigns.create_update_channel(args) do
      {:ok, %{update_channel: update_channel}}
    end
  end

  def update_update_channel(args, _resolution) do
    with {:ok, %UpdateChannel{} = update_channel} <-
           UpdateCampaigns.fetch_update_channel(args.update_channel_id),
         {:ok, %UpdateChannel{} = update_channel} <-
           UpdateCampaigns.update_update_channel(update_channel, args) do
      {:ok, %{update_channel: update_channel}}
    end
  end

  def delete_update_channel(args, _resolution) do
    with {:ok, %UpdateChannel{} = update_channel} <-
           UpdateCampaigns.fetch_update_channel(args.update_channel_id),
         {:ok, %UpdateChannel{} = update_channel} <-
           UpdateCampaigns.delete_update_channel(update_channel) do
      {:ok, %{update_channel: update_channel}}
    end
  end

  @doc """
  Resolve the update_channel for a device group, batching it for all device groups.

  This allows retrieving the list for all device_groups by doing one a single query.
  """
  def batched_update_channel_for_device_group(device_group, _args, %{context: context}) do
    # We have to pass the tenant_id to the batch function since it gets executed in a separate process
    tenant_id = context.current_tenant.tenant_id

    batch(
      {__MODULE__, :update_channels_by_device_group_id, tenant_id},
      device_group.id,
      fn batch_results ->
        {:ok, Map.get(batch_results, device_group.id)}
      end
    )
  end

  def update_channels_by_device_group_id(tenant_id, device_group_ids) do
    # Use the correct tenant_id in the batching process
    Edgehog.Repo.put_tenant_id(tenant_id)

    UpdateCampaigns.get_update_channels_for_device_group_ids(device_group_ids)
  end
end
