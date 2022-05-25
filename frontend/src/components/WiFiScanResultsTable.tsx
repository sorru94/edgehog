/*
  This file is part of Edgehog.

  Copyright 2021,2022 SECO Mind Srl

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

import { FormattedDate, FormattedMessage } from "react-intl";
import { graphql, useFragment } from "react-relay";

import type {
  WiFiScanResultsTable_wifiScanResults$data,
  WiFiScanResultsTable_wifiScanResults$key,
} from "api/__generated__/WiFiScanResultsTable_wifiScanResults.graphql";

import Result from "components/Result";
import Table from "components/Table";
import type { Column } from "components/Table";

// We use graphql fields below in columns configuration
/* eslint-disable relay/unused-fields */
const WIFI_SCAN_RESULTS_TABLE_FRAGMENT = graphql`
  fragment WiFiScanResultsTable_wifiScanResults on Device {
    wifiScanResults {
      channel
      essid
      macAddress
      rssi
      timestamp
    }
  }
`;

type TableRecord = NonNullable<
  WiFiScanResultsTable_wifiScanResults$data["wifiScanResults"]
>[0];

const columns: Column<TableRecord>[] = [
  {
    accessor: "essid",
    Header: (
      <FormattedMessage
        id="components.WiFiScanResultsTable.apEssidTitle"
        defaultMessage="ESSID"
      />
    ),
  },
  {
    accessor: "channel",
    Header: (
      <FormattedMessage
        id="components.WiFiScanResultsTable.apChannelTitle"
        defaultMessage="Channel"
      />
    ),
  },
  {
    accessor: "macAddress",
    Header: (
      <FormattedMessage
        id="components.WiFiScanResultsTable.apMacAddressTitle"
        defaultMessage="MAC Address"
      />
    ),
  },
  {
    accessor: "rssi",
    Header: (
      <FormattedMessage
        id="components.WiFiScanResultsTable.apRssiTitle"
        defaultMessage="RSSI"
      />
    ),
    Cell: ({ value }) => (value ? `${value} dBm` : ""),
  },
  {
    accessor: "timestamp",
    Header: (
      <FormattedMessage
        id="components.WiFiScanResultsTable.seenAtTitle"
        defaultMessage="Seen at"
      />
    ),
    Cell: ({ value }) => (
      <FormattedDate
        value={new Date(value)}
        year="numeric"
        month="long"
        day="numeric"
        hour="numeric"
        minute="numeric"
      />
    ),
  },
];

interface Props {
  className?: string;
  deviceRef: WiFiScanResultsTable_wifiScanResults$key;
}

const WiFiScanResultsTable = ({ className, deviceRef }: Props) => {
  const data = useFragment(WIFI_SCAN_RESULTS_TABLE_FRAGMENT, deviceRef);

  if (!data.wifiScanResults || !data.wifiScanResults.length) {
    return (
      <Result.EmptyList
        title={
          <FormattedMessage
            id="pages.Device.wifiScanResultsTab.noResults.title"
            defaultMessage="No results"
          />
        }
      >
        <FormattedMessage
          id="pages.Device.wifiScanResultsTab.noResults.message"
          defaultMessage="The device has not detected any WiFi AP yet."
        />
      </Result.EmptyList>
    );
  }

  const wifiScanResults = data.wifiScanResults.map((scanResult) => ({
    ...scanResult,
  }));

  return (
    <Table className={className} columns={columns} data={wifiScanResults} />
  );
};

export default WiFiScanResultsTable;
