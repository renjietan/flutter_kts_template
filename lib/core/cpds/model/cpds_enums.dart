enum CpdsDeviceType {
  unspecified(0, 'UNSPECIFIED'),
  server(1, 'SERVER'),
  hf(2, 'HF'),
  multiBandRadio(3, 'MULTI_BAND_RADIO'),
  multiBandHandheld(4, 'MULTI_BAND_HANDHELD'),
  ccu(5, 'CCU'),
  iec(6, 'IEC'),
  smallHandheld(7, 'SMALL_HANDHELD'),
  ccuAudio(8, 'CCU_AUDIO'),
  vehInter(9, 'VEH_INTER');

  const CpdsDeviceType(this.value, this.apiName);

  final int value;
  final String apiName;

  static CpdsDeviceType fromValue(Object? value) {
    final parsed = _asInt(value);
    for (final type in values) {
      if (type.value == parsed) return type;
    }
    return CpdsDeviceType.unspecified;
  }

  static CpdsDeviceType fromApiName(Object? value) {
    final name = value?.toString().toUpperCase() ?? '';
    for (final type in values) {
      if (type.apiName == name) return type;
    }
    return CpdsDeviceType.unspecified;
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

enum CpdsErrorCode {
  unspecified(0, 'ERROR_CODE_UNSPECIFIED'),
  invalidMessage(1, 'ERROR_CODE_INVALID_MESSAGE'),
  invalidPackage(2, 'ERROR_CODE_INVALID_PACKAGE'),
  packageTooLarge(3, 'ERROR_CODE_PACKAGE_TOO_LARGE'),
  invalidZipSize(4, 'ERROR_CODE_INVALID_ZIP_SIZE'),
  insufficientStorage(5, 'ERROR_CODE_INSUFFICIENT_STORAGE'),
  authAssignmentConflict(6, 'ERROR_CODE_AUTH_ASSIGNMENT_CONFLICT'),
  authConflict(7, 'ERROR_CODE_AUTH_CONFLICT'),
  authBindingMissing(8, 'ERROR_CODE_AUTH_BINDING_MISSING'),
  busy(9, 'ERROR_CODE_BUSY'),
  fileSizeMismatch(10, 'ERROR_CODE_FILE_SIZE_MISMATCH'),
  fileHashMismatch(11, 'ERROR_CODE_FILE_HASH_MISMATCH'),
  storageIoError(12, 'ERROR_CODE_STORAGE_IO_ERROR'),
  parseOutputFailed(13, 'ERROR_CODE_PARSE_OUTPUT_FAILED'),
  parseTimeout(14, 'ERROR_CODE_PARSE_TIMEOUT'),
  outputWriteFailed(15, 'ERROR_CODE_OUTPUT_WRITE_FAILED'),
  skippedAfterPreviousFailure(16, 'ERROR_CODE_SKIPPED_AFTER_PREVIOUS_FAILURE'),
  sessionTimeout(17, 'ERROR_CODE_SESSION_TIMEOUT'),
  discoveryMismatch(18, 'ERROR_CODE_DISCOVERY_MISMATCH'),
  esnConflict(19, 'ERROR_CODE_ESN_CONFLICT'),
  authTimeout(20, 'ERROR_CODE_AUTH_TIMEOUT'),
  transferSilenceTimeout(21, 'ERROR_CODE_TRANSFER_SILENCE_TIMEOUT'),
  transferNoProgress(22, 'ERROR_CODE_TRANSFER_NO_PROGRESS'),
  networkInterfaceError(23, 'ERROR_CODE_NETWORK_INTERFACE_ERROR');

  const CpdsErrorCode(this.value, this.apiName);

  final int value;
  final String apiName;

  static CpdsErrorCode fromValue(Object? value) {
    final parsed = _asInt(value);
    for (final code in values) {
      if (code.value == parsed) return code;
    }
    return CpdsErrorCode.unspecified;
  }

  static CpdsErrorCode fromApiName(Object? value) {
    final name = value?.toString().toUpperCase() ?? '';
    for (final code in values) {
      if (code.apiName == name) return code;
    }
    return CpdsErrorCode.unspecified;
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

enum CpdsActiveState {
  idle('IDLE'),
  discovering('DISCOVERING'),
  awaitingDiscoveryConfirmation('AWAITING_DISCOVERY_CONFIRMATION'),
  authenticating('AUTHENTICATING'),
  transferring('TRANSFERRING'),
  waitingParse('WAITING_PARSE'),
  drainingAfterFailure('DRAINING_AFTER_FAILURE'),
  completed('COMPLETED'),
  partialSuccess('PARTIAL_SUCCESS'),
  failed('FAILED');

  const CpdsActiveState(this.apiName);

  final String apiName;

  static CpdsActiveState fromApiName(Object? value) {
    final name = value?.toString().toUpperCase() ?? '';
    for (final state in values) {
      if (state.apiName == name) return state;
    }
    return CpdsActiveState.idle;
  }
}

enum CpdsDeviceStatus {
  pending('PENDING'),
  discovered('DISCOVERED'),
  authenticated('AUTHENTICATED'),
  receiving('RECEIVING'),
  waitingParse('WAITING_PARSE'),
  completed('COMPLETED'),
  failed('FAILED'),
  ignored('IGNORED');

  const CpdsDeviceStatus(this.apiName);

  final String apiName;

  static CpdsDeviceStatus fromApiName(Object? value) {
    final name = value?.toString().toUpperCase() ?? '';
    for (final status in values) {
      if (status.apiName == name) return status;
    }
    return CpdsDeviceStatus.pending;
  }
}
