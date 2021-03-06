//
//  OrderCategoryViewController.swift
//  Hot
//
//  Created by 周欣 on 2016/12/30.
//  Copyright © 2016年 zhou. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import RxDataSources

protocol OrderCategoryViewControllerDelegate: NSObjectProtocol {
    func orderCategoryViewController(_ controller: OrderCategoryViewController, isSelectDish: Bool)
}

class OrderCategoryViewController: UIViewController {

    enum ScrollType {
        case fromUser
        case fromCollectionView
    }
    
    fileprivate lazy var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: .plain)
        tableView.rowHeight = 60
        tableView.sectionHeaderHeight = 60
        tableView.sectionFooterHeight = 0.01
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tableView
    }()
    
    var scrollType = ScrollType.fromUser
    let disposeBag = DisposeBag()
    var dataSource : RxTableViewSectionedReloadDataSource<RxSectionModel>!
    var sections = Variable([RxSectionModel]())
    var button = UIButton()
    
    weak var delegate: OrderCategoryViewControllerDelegate?
    
    let dishDataList = DishViewModel.fetchAllDish()
    let potCategory = DishViewModel.fetchAllPot()
    weak var orderDishController: OrderDishViewController?
    weak var orderPotController: OrderDishViewController?
    var tableViewModel: TableViewModel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let dataSource = RxTableViewSectionedReloadDataSource<RxSectionModel>()
        dataSource.configureCell = { ds, tv, ip, item in
            let cell = tv.dequeueReusableCell(withIdentifier: "cell", for: ip)
            cell.textLabel?.text = item.title
            return cell
        }

        self.dataSource = dataSource
        
        
        let sections = makeRxViewModel()
        self.sections.value = sections
        
        self.sections.asObservable()
        .bindTo(tableView.rx.items(dataSource: dataSource))
        .addDisposableTo(disposeBag)
        
        tableView.rx
            .itemSelected
            .subscribe(onNext: { indexPath in
              self.didSelectIndexPath(indexPath)
            })
            .addDisposableTo(disposeBag)
        
        tableView.rx
            .setDelegate(self)
            .addDisposableTo(disposeBag)
        
        makeViews()
        makeViewLayouts()
    }
    
    fileprivate func makeRxViewModel() -> [RxSectionModel] {
        return dishDataList.map { (category) -> RxSectionModel in
            let subCategorys = category["subCategorys"] as! [JSONDictionary]
            var rows = subCategorys.map({ (subCategory) -> RxRowModel in
                return RxRowModel(title: subCategory["CLASSNAME"] as! String)
            })
            if self.button.title(for: .normal) == category["CATEGORYNAME"] as? String {
                
            }else if self.button.title(for: .normal) == nil, category["CATEGORYNAME"] as! String == "特色菜"{
                
            }else {
                rows = [RxRowModel]()
            }
            return RxSectionModel(headTitle: category["CATEGORYNAME"] as? String, items: rows)
        }
    }
    

    
    
    fileprivate func makeViews() {
        view.addSubview(tableView)
    }
    
    fileprivate func makeViewLayouts() {
        tableView.snp.makeConstraints { (make) in
            make.edges.equalTo(view)
        }
    }
    
    func scrollToIndexPath(_ indexPath: IndexPath) {
        var count = indexPath.section
        var foundflag = 0
        var targetIndexPath: IndexPath?
        for (index, item) in tableViewModel.sections.enumerated() {
            let sectionModel = item as! SectionModel
            count -= sectionModel.rows.count
            if count < 0 && foundflag == 0{
                sectionModel.isSelected = true
                foundflag = 1
                targetIndexPath = IndexPath(row: sectionModel.rows.count + count, section: index)
            }else{
                sectionModel.isSelected = false
            }
        }
        tableView.reloadData()
        if let targetIndexPath = targetIndexPath {
            tableView.selectRow(at: targetIndexPath, animated: true, scrollPosition: .top)
        }
    }
    
    fileprivate func didSelectIndexPath(_ indexPath: IndexPath)
    {
        if indexPath.section == 0 {
            delegate?.orderCategoryViewController(self, isSelectDish: false)
            orderPotController?.scrollToCategoryIndexPath(indexPath)
        }else{
            delegate?.orderCategoryViewController(self, isSelectDish: true)
            orderDishController?.scrollToCategoryIndexPath(indexPath)
        }
    }
}

extension OrderCategoryViewController: UITableViewDelegate
{
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let button = UIButton()
        button.setTitleColor(UIColor.black, for: .normal)
        button.backgroundColor = UIColor.gray
        let sectionModel = dataSource.sectionModels[section]
        button.setTitle(sectionModel.headTitle, for: .normal)
        button.tag = section
        button.addTarget(self, action: #selector(didPressSectionButton(_:)), for: .touchUpInside)
        return button
    }

    @objc private func didPressSectionButton(_ button: UIButton){
        self.button = button
        
        self.sections.value = makeRxViewModel()
        scrollType = .fromUser

        tableView.reloadData()
        tableView.selectRow(at: IndexPath(row: 0, section: button.tag), animated: true, scrollPosition: .top)
        didSelectIndexPath(IndexPath(row: 0, section: button.tag))
    }
}

//fileprivate func makeViewModel() {
//    tableViewModel = TableViewModel()
//    var sections :[SectionModel] = [SectionModel]()
//    let potCategory = makeSectionModel(self.potCategory)
//    let dishCategorys = dishDataList.map { (category) -> SectionModel in
//        return makeSectionModel(category)
//    }
//    sections.append(potCategory)
//    sections.append(contentsOf: dishCategorys)
//    tableViewModel.sections = sections
//    let firstSectionModel = tableViewModel.sections.first as! SectionModel
//    firstSectionModel.isSelected = true
//}
//
//fileprivate func makeSectionModel(_ category: [String: Any]) -> SectionModel {
//    let sectionModel = SectionModel()
//    sectionModel.rows = category["subCategorys"] as! [Any]
//    sectionModel.headTitle = category["CATEGORYNAME"] as? String
//    return sectionModel
//}

//extension OrderCategoryViewController: UITableViewDelegate, UITableViewDataSource
//{
//    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
//        scrollType = .fromUser
//    }
//    
//    func numberOfSections(in tableView: UITableView) -> Int {
//        return tableViewModel.sections.count
//    }
//    
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        let sectionModel = tableViewModel.sections[section] as! SectionModel
//        var count = 0
//        if  sectionModel.isSelected {
//            let subCategorys = sectionModel.rows as! [[String: Any]]
//            count = subCategorys.count
//        }
//        return count
//    }
//    
//    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let sectionModel = tableViewModel.sections[indexPath.section] as! SectionModel
//        let subCategorys = sectionModel.rows as! [[String: Any]]
//        let subCategory = subCategorys[indexPath.row]
//        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
//        cell.textLabel?.text = subCategory["CLASSNAME"] as? String
//        return cell
//    }
//    
//    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        let button = UIButton()
//        button.setTitleColor(UIColor.black, for: .normal)
//        button.backgroundColor = UIColor.gray
//        let sectionModel = tableViewModel.sections[section] as! SectionModel
//        button.setTitle(sectionModel.headTitle, for: .normal)
//        button.tag = section
//        button.addTarget(self, action: #selector(didPressSectionButton(_:)), for: .touchUpInside)
//        return button
//    }
//    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        scrollType = .fromUser
//        didSelectIndexPath(indexPath)
//    }
//    
//    @objc private func didPressSectionButton(_ button: UIButton){
//        scrollType = .fromUser
//        for (index, item) in tableViewModel.sections.enumerated() {
//            let sectionModel = item as! SectionModel
//            sectionModel.isSelected = button.tag == index
//        }
//        tableView.reloadData()
//        tableView.selectRow(at: IndexPath(row: 0, section: button.tag), animated: true, scrollPosition: .top)
//        didSelectIndexPath(IndexPath(row: 0, section: button.tag))
//    }
//
//}
