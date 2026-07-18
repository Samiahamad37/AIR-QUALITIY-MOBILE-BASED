const deviceIdByLabel = {
  'Mwenge': 'lands-building',
  'Planing Building': 'planing-building',
};

const deviceLabelById = {
  'lands-building': 'Mwenge',
  'planing-building': 'Planing Building',
};

String deviceDisplayName(String deviceId) =>
    deviceLabelById[deviceId] ?? deviceId;
