import 'dart:async';

import 'package:firebase_auth_rest/firebase_auth_rest.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart';

import 'models/timeout.dart';
import 'rest_api.dart';
import 'store.dart';

abstract class FirebaseDatabase {
  StreamSubscription<String> _idTokenSub;

  final FirebaseAccount account;
  final RestApi api;
  final FirebaseStore<dynamic> rootStore;

  FirebaseDatabase.api(
    this.api, [
    this.account,
  ]) : rootStore = FirebaseStore<dynamic>.apiCreate(
          restApi: api,
          subPaths: [],
          onDataFromJson: (dynamic json) => json,
          onDataToJson: (dynamic data) => data,
          onPatchData: (dynamic data, updatedFields) =>
              (data as Map<String, dynamic>)..addAll(updatedFields),
        ) {
    if (account != null) {
      _idTokenSub = account.idTokenStream.listen(
        (idToken) => api.idToken = idToken,
        cancelOnError: false,
      );
    }
  }

  // ignore: sort_unnamed_constructors_first
  FirebaseDatabase({
    @required FirebaseAccount account,
    @required String database,
    String basePath = '',
    Timeout timeout,
    WriteSizeLimit writeSizeLimit,
    Client client,
  }) : this.api(
          RestApi(
            client: client ?? account.api.client,
            database: database,
            basePath: basePath,
            idToken: account.idToken,
            timeout: timeout,
            writeSizeLimit: writeSizeLimit,
          ),
          account,
        );

  FirebaseDatabase.unauthenticated({
    @required Client client,
    @required String database,
    String basePath = '',
    Timeout timeout,
    WriteSizeLimit writeSizeLimit,
  }) : this.api(
          RestApi(
            client: client,
            database: database,
            basePath: basePath,
            timeout: timeout,
            writeSizeLimit: writeSizeLimit,
          ),
        );

  Future<void> dispose() async {
    await _idTokenSub?.cancel();
    account?.dispose();
  }

  FirebaseStore<T> createRootStore<T>({
    @required String path,
    @required DataFromJsonCallback<T> onDataFromJson,
    @required DataToJsonCallback<T> onDataToJson,
    @required PatchDataCallback<T> onPatchData,
    String loggingCategory = FirebaseStore.loggingTag,
  }) =>
      FirebaseStore.apiCreate(
        restApi: api,
        subPaths: [],
        onDataFromJson: onDataFromJson,
        onDataToJson: onDataToJson,
        onPatchData: onPatchData,
      );
}
