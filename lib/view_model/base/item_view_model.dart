import 'base_view_model.dart';

abstract class ItemViewModel<T> extends BaseViewModel {
  T? item;

  initData() async {
    setBusy();
    await refresh(init: true);
  }
  
  refresh({bool init = false}) async {
    try {
      T data = await loadData();
      if (data == null) {
        item = null;
        setEmpty();
      } else {
        onCompleted(data);
        item = data;
        setIdle();
      }
    } catch (e) {
      if (init) item = null;
      setError(e);
    }
  }

  // 加载数据
  Future<T> loadData();//抽象方法

  onCompleted(T data) {}
}