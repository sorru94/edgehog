/*
  This file is part of Edgehog.

  Copyright 2022 SECO Mind Srl

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

  SPDX-License-Identifier: Apache-2.0
*/

import { Suspense, useEffect } from "react";
import { FormattedMessage } from "react-intl";
import { ErrorBoundary } from "react-error-boundary";
import graphql from "babel-plugin-relay/macro";
import {
  usePreloadedQuery,
  useQueryLoader,
  PreloadedQuery,
} from "react-relay/hooks";

import type { DeviceGroups_getDeviceGroups_Query } from "api/__generated__/DeviceGroups_getDeviceGroups_Query.graphql";
import Button from "components/Button";
import Center from "components/Center";
import DeviceGroupsTable from "components/DeviceGroupsTable";
import Page from "components/Page";
import Spinner from "components/Spinner";
import { Link, Route } from "Navigation";

const GET_DEVICE_GROUPS_QUERY = graphql`
  query DeviceGroups_getDeviceGroups_Query {
    deviceGroups {
      ...DeviceGroupsTable_DeviceGroupFragment
    }
  }
`;

interface DeviceGroupsContentProps {
  getDeviceGroupsQuery: PreloadedQuery<DeviceGroups_getDeviceGroups_Query>;
}

const DeviceGroupsContent = ({
  getDeviceGroupsQuery,
}: DeviceGroupsContentProps) => {
  const { deviceGroups } = usePreloadedQuery(
    GET_DEVICE_GROUPS_QUERY,
    getDeviceGroupsQuery
  );

  return (
    <Page>
      <Page.Header
        title={
          <FormattedMessage
            id="pages.DeviceGroups.title"
            defaultMessage="Groups"
          />
        }
      >
        <Button as={Link} route={Route.deviceGroupsNew}>
          <FormattedMessage
            id="pages.DeviceGroups.createButton"
            defaultMessage="Create Group"
          />
        </Button>
      </Page.Header>
      <Page.Main>
        <DeviceGroupsTable deviceGroupsRef={deviceGroups} />
      </Page.Main>
    </Page>
  );
};

const DevicesPage = () => {
  const [getDeviceGroupsQuery, getDeviceGroups] =
    useQueryLoader<DeviceGroups_getDeviceGroups_Query>(GET_DEVICE_GROUPS_QUERY);

  useEffect(() => getDeviceGroups({}), [getDeviceGroups]);

  return (
    <Suspense
      fallback={
        <Center data-testid="page-loading">
          <Spinner />
        </Center>
      }
    >
      <ErrorBoundary
        FallbackComponent={(props) => (
          <Center data-testid="page-error">
            <Page.LoadingError onRetry={props.resetErrorBoundary} />
          </Center>
        )}
        onReset={() => getDeviceGroups({})}
      >
        {getDeviceGroupsQuery && (
          <DeviceGroupsContent getDeviceGroupsQuery={getDeviceGroupsQuery} />
        )}
      </ErrorBoundary>
    </Suspense>
  );
};

export default DevicesPage;
