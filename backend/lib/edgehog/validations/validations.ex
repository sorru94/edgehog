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

defmodule Edgehog.Validations do
  alias Ash.Resource.Validation

  def locale(attribute) do
    {Validation.Match,
     attribute: attribute, match: ~r/^[a-z]{2,3}-[A-Z]{2}$/, message: "is not a valid locale"}
  end

  def slug(attribute) do
    {Validation.Match,
     attribute: attribute,
     match: ~r/^[a-z\d\-]+$/,
     message: "should only contain lower case ASCII letters (from a to z), digits and -"}
  end
end
