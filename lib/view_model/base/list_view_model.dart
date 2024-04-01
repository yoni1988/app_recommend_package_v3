import 'base_view_model.dart';

abstract class ListViewModel<T> extends BaseViewModel {
  List<T> list = [];

  initData() async {
    setBusy();
    list = [];
    notifyListeners();
    await refresh(init: true);
    print("list=="+list.length.toString());
    notifyListeners();
  }
  
  refresh({bool init = false}) async {
    try {
      List<T> data = await loadData();
      if (data.isEmpty) {
        list.clear();
        setEmpty();
      } else {
        onCompleted(data);
        list.clear();
        list.addAll(data);
        setIdle();
      }
    } catch (e, s) {
      if (init) list.clear();
      setError(e);
    }
  }

  // 加载数据
  Future<List<T>> loadData();//抽象方法

  onCompleted(List<T> data) {}
}