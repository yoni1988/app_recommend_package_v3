
import 'list_view_model.dart';

abstract class RefreshListViewModel<T> extends ListViewModel<T> {
  /// 分页第一页页码
  static const int pageNumFirst = 0;

  /// 分页条目数量
  static const int pageSize = 15;

  /// 当前页码
  int _currentPageNum = pageNumFirst;

  // EasyRefreshController _refreshController = EasyRefreshController();

  // EasyRefreshController get refreshController => _refreshController;

  Future<List<T>?> refresh({bool init = false}) async {
    print('CopyListViewModel refresh');
    try {
      _currentPageNum = pageNumFirst;
      var data = await loadData(pageNum: pageNumFirst);
      if (data.isEmpty) {
        // refreshController.finishRefresh();
        list.clear();
        setEmpty();
      } else {
        onCompleted(data);
        list.clear();
        list.addAll(data);
        // 小于分页的数量,禁止上拉加载更多
        if (data.length < pageSize) {
          // refreshController.finishRefresh(noMore: true);
        } else {
          // refreshController.finishRefresh();
        }
        setIdle();
      }
      return data;
    } catch (e, s) {
      /// 页面已经加载了数据,如果刷新报错,不应该直接跳转错误页面
      /// 而是显示之前的页面数据.给出错误提示
      if (init) list.clear();
      // refreshController.finishRefresh(success: false);
      setError(e);
      return null;
    }
  }

  /// 上拉加载更多
  Future<List<T>?> loadMore() async {
    try {
      var data = await loadData(pageNum: ++_currentPageNum);
      if (data.isEmpty) {
        _currentPageNum--;
        // refreshController.finishLoad(noMore: true);
      } else {
        onCompleted(data);
        list.addAll(data);
        if (data.length < pageSize) {
          // refreshController.finishLoad(noMore: true);
        } else {
          // refreshController.finishLoad();
        }
        notifyListeners();
      }
      return data;
    } catch (e, s) {
      _currentPageNum--;
      // refreshController.finishLoad(success: false);
      return null;
    }
  }

  // 加载数据
  Future<List<T>> loadData({int pageNum});

  @override
  void dispose() {
    // _refreshController.dispose();
    super.dispose();
  }
}