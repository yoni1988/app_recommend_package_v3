import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '/config/apis.dart';
import 'view_state.dart';

class BaseViewModel extends ChangeNotifier {
  /// 防止页面销毁后,异步任务才完成,导致报错
  bool _disposed = false;

  /// 当前的页面状态
  ViewState _viewState;

  ViewStateError? _viewStateError;

  BaseViewModel({ViewState? viewState})
      : _viewState = viewState ?? ViewState.idle {
    debugPrint('BaseViewModel---constructor--->$runtimeType');
  }

  /// ViewState
  ViewState get viewState => _viewState;

  set viewState(ViewState viewState) {
    _viewStateError = null;
    _viewState = viewState;
    notifyListeners();
  }

  void setViewStateNotNotify(ViewState state) {
    _viewState = state;
  }

  /// set
  void setIdle() {
    viewState = ViewState.idle;
  }

  void setBusy() {
    viewState = ViewState.busy;
  }

  void setEmpty() {
    viewState = ViewState.empty;
  }

  ViewStateError? get viewStateError => _viewStateError;

  /// [e]分类Error和Exception两种
  void setError(e, {String? message}) {
    ViewStateErrorType errorType = ViewStateErrorType.defaultError;

    /// 见https://github.com/flutterchina/dio/blob/master/README-ZH.md#dioerrortype
    if (e is DioError) {
      if (e.type == DioErrorType.connectTimeout ||
          e.type == DioErrorType.sendTimeout ||
          e.type == DioErrorType.receiveTimeout) {
        // timeout
        errorType = ViewStateErrorType.networkTimeOutError;
        message = e.error;
      } else if (e.type == DioErrorType.response) {
        // incorrect status, such as 404, 503...
        message = e.error;
      } else if (e.type == DioErrorType.cancel) {
        // to be continue...
        message = e.error;
        // }else if(e is String) {

      } else {
        // dio将原error重新套了一层
        e = e.error;
        if (e is UnAuthorizedException) {
          errorType = ViewStateErrorType.unauthorizedError;
        } else if (e is NotSuccessException) {
          message = e.message;
        } else if (e is SocketException) {
          errorType = ViewStateErrorType.networkTimeOutError;
          message = e.message;
        } else {
          message = e.message;
        }
      }
    }else {
      if (e is UnAuthorizedException) {
        errorType = ViewStateErrorType.unauthorizedError;
      } else if (e is NotSuccessException) {
        message = e.message;
      } else if (e is SocketException) {
        errorType = ViewStateErrorType.networkTimeOutError;
        message = e.message;
      } else {
        errorType = ViewStateErrorType.defaultError;
        message = '未知错误';
      }
    }
    viewState = ViewState.error;
    _viewStateError = ViewStateError(
      errorType,
      message: message??'未知错误',
      errorMessage: e.toString(),
    );
    onError(_viewStateError!);
  }

  void onError(ViewStateError viewStateError) {}

  @override
  String toString() {
    return 'BaseModel{_viewState: $viewState, _viewStateError: $_viewStateError}';
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    debugPrint('view_state_model dispose -->$runtimeType');
    super.dispose();
  }
}
