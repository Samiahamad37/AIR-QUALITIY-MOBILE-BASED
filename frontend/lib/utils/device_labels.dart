const deviceIdByLabel = {
  'Lands Building': 'lands-building',
  'Planing Building': 'planing-building',
};

const deviceLabelById = {
  'lands-building': 'Lands Building',
  'planing-building': 'Planing Building',
};

String deviceDisplayName(String deviceId) =>
    deviceLabelById[deviceId] ?? deviceId;
