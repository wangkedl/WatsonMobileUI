import Foundation

/*
  数据提供协议
*/
protocol ChatDataSource
{
    func rowsForChatTable( tableView:TableView) -> Int
    
    func chatTableView(tableView:TableView, dataForRow:Int)-> MessageItem
}