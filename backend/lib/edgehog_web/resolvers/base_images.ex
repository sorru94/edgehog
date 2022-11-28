#
# This file is part of Edgehog.
#
# Copyright 2022 SECO Mind Srl
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

defmodule EdgehogWeb.Resolvers.BaseImages do
  alias Edgehog.BaseImages
  alias Edgehog.BaseImages.BaseImageCollection
  alias Edgehog.Devices
  alias Edgehog.Devices.SystemModel
  alias EdgehogWeb.Resolvers

  def find_base_image_collection(args, resolution) do
    with {:ok, base_image_collection} <- BaseImages.fetch_base_image_collection(args.id) do
      base_image_collection =
        Resolvers.Devices.preload_localized_system_model(
          base_image_collection,
          resolution.context
        )

      {:ok, base_image_collection}
    end
  end

  def list_base_image_collections(_args, resolution) do
    base_image_collections =
      BaseImages.list_base_image_collections()
      |> Resolvers.Devices.preload_localized_system_model(resolution.context)

    {:ok, base_image_collections}
  end

  def create_base_image_collection(attrs, resolution) do
    with {:ok, %SystemModel{} = system_model} <-
           Devices.fetch_system_model(attrs.system_model_id),
         {:ok, base_image_collection} <-
           BaseImages.create_base_image_collection(system_model, attrs) do
      base_image_collection =
        Resolvers.Devices.preload_localized_system_model(
          base_image_collection,
          resolution.context
        )

      {:ok, %{base_image_collection: base_image_collection}}
    end
  end

  def update_base_image_collection(attrs, resolution) do
    with {:ok, %BaseImageCollection{} = base_image_collection} <-
           BaseImages.fetch_base_image_collection(attrs.base_image_collection_id),
         {:ok, %BaseImageCollection{} = base_image_collection} <-
           BaseImages.update_base_image_collection(base_image_collection, attrs) do
      base_image_collection =
        Resolvers.Devices.preload_localized_system_model(
          base_image_collection,
          resolution.context
        )

      {:ok, %{base_image_collection: base_image_collection}}
    end
  end

  def delete_base_image_collection(args, resolution) do
    with {:ok, %BaseImageCollection{} = base_image_collection} <-
           BaseImages.fetch_base_image_collection(args.base_image_collection_id),
         {:ok, %BaseImageCollection{} = base_image_collection} <-
           BaseImages.delete_base_image_collection(base_image_collection) do
      base_image_collection =
        Resolvers.Devices.preload_localized_system_model(
          base_image_collection,
          resolution.context
        )

      {:ok, %{base_image_collection: base_image_collection}}
    end
  end
end
