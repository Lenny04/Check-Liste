//
//  ViewController.swift
//  Check Liste
//
//  Created by linoj ravindran on 21/02/2016.
//  Copyright © 2016 linoj ravindran. All rights reserved.
//

import UIKit
import M13Checkbox
import Firebase
import FirebaseDatabase
import FirebaseAuth
import FirebaseFirestore
import Floaty
class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, FloatyDelegate {
    var list = [ListItem]()
    var sortedList = [ListItem]()
    var currentIndex = 0
    var refreshControl: UIRefreshControl!
    var listForSegue = List(listName: "", keyID: "")
    @IBOutlet weak var tableView1: UITableView!
    @IBOutlet weak var sortButton: UIBarButtonItem!
    @IBOutlet private weak var lastUpdateButton: UIBarButtonItem!
    var lastUpdateLabel = UILabel()
    var ref: DocumentReference!
    lazy var db = Firestore.firestore()
    var quoteListener: ListenerRegistration!
    //var f = Floaty()
    var visibleRows = [Int]()
    let filter : UIImage = UIImage(named: "Filter")!
    let filtered : UIImage = UIImage(named: "Filtered")!
    var filteredStatus = false
    override func viewDidAppear(_ animated: Bool) {
        self.tableView1.reloadData()
        updateLabel()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView1.delegate = self
        tableView1.dataSource = self
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        tableView1.addGestureRecognizer(longPressRecognizer)
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Refreshing")
        refreshControl.addTarget(self, action: #selector(ViewController.refresh), for:.valueChanged)
        tableView1.addSubview(refreshControl)
        self.navigationItem.title = listForSegue.getListName()
        let settings = db.settings
        settings.areTimestampsInSnapshotsEnabled = true
        db.settings = settings
        let tap = UITapGestureRecognizer(target: self, action: #selector(tableTapped))
        tableView1.addGestureRecognizer(tap)
//        f.addItem("Sorter efter fuldførte", icon: UIImage(named: "Checkmark.png"), titlePosition: .left) { (item) in
//            if(item.title == "Sorter efter fuldførte"){
//                self.list.sort {!$0.getchecked() && $1.getchecked()}
//                self.tableView1.reloadData()
//                item.title = "Sorter efter alfabetisk"
//                item.icon = UIImage(named: "ABC")
//            }
//            else if(item.title == "Sorter efter alfabetisk"){
//                self.list.sort {$0.getItemDescription() < $1.getItemDescription()}
//                self.tableView1.reloadData()
//                item.title = "Sorter efter fuldførte"
//                item.icon = UIImage(named: "Checkmark.png")
//            }
//            self.f.close()
//        }
//        f.addItem("Tilføj nyt element", icon: UIImage(named: "write_new"), titlePosition: .left) { (item) in
//            self.tilføjNytElement()
//            self.f.close()
//        }
//        f.itemTitleColor = UIColor.white
//        f.fabDelegate = self
//        self.view.addSubview(f)
        quoteListener = db.collection("Lister/\(listForSegue.getKeyID())/Elementer").addSnapshotListener { (querySnapshot, err) in
            if err != nil {
                //print("Error getting documents: \(err)")
            } else {
                querySnapshot?.documentChanges.forEach { diff in
//                    print("Current index at fetching: \(self.currentIndex)")
                    if (diff.type == .added){
                        self.list.append(ListItem(itemDescription: "", checked: false, keyID: diff.document.documentID))
                        let value1 = diff.document.data() as NSDictionary
                        for (key, value) in value1 {
                            let notenu = key as! String
                            switch notenu{
                            case "Navn":
                                self.list[self.list.count-1].setItemDescription(a: value as! String)
                                break
                            case "Checked Status":
                                self.list[self.list.count-1].setChecked(b: value as! Bool)
                                break
                            default:
                                self.tableView1.reloadData()
                            }
                        }
                        //print("Document: \(self.list[self.list.count-1].getItemDescription()), added in firestore")
                        self.tableView1.reloadData()
                        self.updateLabel()
                    }
                    if(diff.type == .modified) {
                        //print("Modified the document in firestore")
                        let value1 = diff.document.data() as NSDictionary
                        let changedIndex = self.list.index(where: {$0.getKeyID() == diff.document.documentID})
                        for (key, value) in value1 {
                            let notenu = key as! String
                            if(notenu == "Navn"){
                                //var changedIndex = self.list.first(where: { $0.getKeyID() == diff.document.documentID })?.getKeyID()
                                //var c = self.list.index{$0.getKeyID() === diff.document.documentID}
                                self.list[changedIndex!].setItemDescription(a: value as! String)
                            }
                            else if(notenu == "Checked Status"){
                                self.list[changedIndex!].setChecked(b: value as! Bool)
                            }
                        }
                        self.list.sort {$0.getItemDescription() < $1.getItemDescription()}
                        self.tableView1.reloadData()
                        self.updateLabel()
                    }
                    if(diff.type == .removed) {
                        //print("Document removed from firestore")
                        self.tableView1.reloadData()
                        self.updateLabel()
                    }
                }
                self.list.sort {$0.getItemDescription() < $1.getItemDescription()}
                self.sortedList.removeAll()
                for item in self.list {
                    if(item.getchecked() == false){
                        self.sortedList.append(ListItem(itemDescription: item.getItemDescription(), checked: false, keyID: item.getKeyID()))
//                        print("Appending: \(item.getItemDescription()) to sorteList")
                    }
                    else{
                        
                    }
                }
            }
            self.updateLabel()
        }
        self.tableView1.reloadData()
        self.navigationController?.setToolbarHidden(false, animated: true)
        
        self.sortedList.sort {$0.getItemDescription() < $1.getItemDescription()}
        lastUpdateLabel.sizeToFit()
        lastUpdateLabel.backgroundColor = UIColor.clear
        lastUpdateLabel.textColor = UIColor.black
        lastUpdateLabel.textAlignment = .center
        lastUpdateButton.customView = lastUpdateLabel
        lastUpdateButton.tintColor = UIColor.black
        lastUpdateButton.isEnabled = true
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        quoteListener.remove()
    }
    @IBAction func tilføjKnap(sender: AnyObject) {
        tilføjNytElement()
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(filteredStatus == true){
            return sortedList.count
        }
        else{
            return list.count
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView1.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CheckListCell
        cell.checkBox.tag = indexPath.row
        cell.checkBox.addTarget(self, action: #selector(ViewController.checkBoxIndex(sender:)), for: UIControl.Event.valueChanged)
//        print("Current index cell for row at: \(self.currentIndex)")
        if(filteredStatus == true){
//            print("Count: \(sortedList.count)")
            if(!sortedList.isEmpty){
//                print("Indexpath: \(indexPath.row)")
                cell.checkBoxtext.text = sortedList[indexPath.row].getItemDescription()
                if(sortedList[indexPath.row].checked == true){
                    cell.checkBox.setCheckState(M13Checkbox.CheckState.checked, animated: true)
                }
                else if(sortedList[indexPath.row].checked == false){
                    cell.checkBox.setCheckState(M13Checkbox.CheckState.unchecked, animated: true)
                }
                
            }
            else{
                
            }
            cell.contentView.addSubview(cell.checkBox)
        }
        else{
            if(!list.isEmpty){
                cell.checkBoxtext.text = list[indexPath.row].getItemDescription()
                if(list[indexPath.row].checked == true){
                    cell.checkBox.setCheckState(M13Checkbox.CheckState.checked, animated: true)
                }
                else if(list[indexPath.row].checked == false){
                    cell.checkBox.setCheckState(M13Checkbox.CheckState.unchecked, animated: true)
                }
                
            }
            else{
                
            }
            cell.contentView.addSubview(cell.checkBox)
            
        }
        
        //print(tableView.indexPathsForVisibleRows!)
//        let dic = tableView.indexPathsForVisibleRows!
//        visibleRows = []
//        for d in dic{
//            visibleRows.append(d.row)
//        }
        updateLabel()
        return cell
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    }
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let cIndex = indexPath.row
        //let numberInList = self.list.count
//        if(cIndex == visibleRows.last!-3){
//            self.f.paddingY = 130
//        }
//        else if(cIndex == visibleRows.last!-1 || cIndex == visibleRows.last!-2){
//            self.f.paddingY = 100
//        }
        let deleteRowAction = UITableViewRowAction(style: UITableViewRowAction.Style.default, title: "Slet", handler:{action, indexpath in
            var listElementKey = ""
            if self.filteredStatus == true {
                listElementKey = self.sortedList[indexPath.row].getKeyID()
                self.sortedList.remove(at: indexPath.row)
            } else {
               listElementKey = self.list[indexPath.row].getKeyID()
                self.list.remove(at: indexPath.row)
            }
            self.db.collection("Lister/\(self.listForSegue.getKeyID())/Elementer").document(listElementKey).delete() { err in
                if err != nil {
                    //print("Error removing document: \(err)")
                } else {
                    //print("Document successfully removed!")
                }
            }
            self.tableView1.reloadData()
        })
        
        return [deleteRowAction]
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //let cell = tableView1.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CheckListCell
        let selectedCell = tableView.cellForRow(at: indexPath as IndexPath)! as! CheckListCell
        //selectedCell.checkBox.setCheckState(M13Checkbox.CheckState.checked, animated: true)
//        print("Current index at did select: \(self.currentIndex)")
        cellIsClicked(a: indexPath.row)
        tableView.deselectRow(at: indexPath, animated: true)
        tableView1.reloadData()
        
    }
    @objc func checkBoxIndex(sender: AnyObject?){
        guard let tappedView = sender!.viewWithTag((sender?.tag)!) else {
            return
        }
        let touchPointInTableView = self.tableView1.convert(tappedView.center, from: tappedView)
        guard let indexPath = self.tableView1.indexPathForRow(at: touchPointInTableView) else {
            return
        }
        cellIsClicked(a: indexPath.row)
        tableView1.reloadData()
    }
    func cellIsClicked(a: Int){
        var itemDescription = ""
        var listKey = ""
        var updatedCheckStatus = false
        if(filteredStatus == true){
            if(sortedList[a].getchecked() == false){
                sortedList[a].setChecked(b: true)
            }
            else{
                sortedList[a].setChecked(b: false)
            }
            itemDescription = self.sortedList[a].getItemDescription()
            listKey = self.sortedList[a].getKeyID()
            updatedCheckStatus = self.sortedList[a].getchecked()
//            print("\(a): \(self.sortedList[a].getItemDescription())")
            self.sortedList.remove(at: a)
        }
        else{
            currentIndex = a
            if(list[a].getchecked() == false){
                list[a].setChecked(b: true)
                //print("Checked status: \(list[a].getItemDescription()): \(list[a].getchecked())")
            }
            else{
                list[a].setChecked(b: false)
                //print("Checked status: \(list[a].getItemDescription()): \(list[a].getchecked())")
            }
            itemDescription = self.list[a].getItemDescription()
            listKey = self.list[a].getKeyID()
            updatedCheckStatus = self.list[a].getchecked()
        }
        self.ref = self.db.collection("Lister/\(listForSegue.getKeyID())/Elementer").document(listKey)
        self.ref.updateData(["Navn" : itemDescription, "Checked Status": updatedCheckStatus], completion: { (err) in
            if err != nil {
                //print("Error editing document: \(err)")
            } else {
                //print("Document with ID: \(self.ref!.documentID) edited")
            }
        })
        updateLabel()
//        print("Current index at cell clicked: \(self.currentIndex)")
    }
    @objc func refresh() {
        tableView1.reloadData()
        //self.f.paddingY = 64
        refreshControl.endRefreshing()
    }
    @objc func tableTapped(tap:UITapGestureRecognizer){
        let location = tap.location(in: self.tableView1)
        let path = self.tableView1.indexPathForRow(at: location)
        if(path != nil && tableView1.isEditing == false){
            cellIsClicked(a: (path?.row)!)
            tableView1.deselectRow(at: path!, animated: true)
            tableView1.reloadData()
        }
        //self.f.paddingY = 14
    }
    @objc func longPress(_ guesture: UILongPressGestureRecognizer) {
        if guesture.state == UIGestureRecognizer.State.began {
            let point = guesture.location(in: tableView1)
            let indexPath = tableView1.indexPathForRow(at: point)
            if(filteredStatus == false){
                currentIndex = indexPath!.row
            }
            else{
                
            }
//            print(self.list[currentIndex].getItemDescription())
//            print("Amount: \(self.sortedList.count):  \(self.sortedList[0].getItemDescription())")
            let editInfo = UIAlertController(title: nil, message: "Info", preferredStyle: UIAlertController.Style.alert)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: { (action) -> Void in
                
            })
            
            let saveAction = UIAlertAction(title: "Gem", style: .default, handler: { (action) -> Void in
                if(!(editInfo.textFields![0].text?.isEmpty)!){
                    var elementKey = ""
                    var updatedListElementDescription = ""
                    var checkedStatus = false
                    if(self.filteredStatus == true){
                        elementKey = self.sortedList[(indexPath?.row)!].getKeyID()
                        updatedListElementDescription = editInfo.textFields![0].text!
                        checkedStatus = self.sortedList[(indexPath?.row)!].getchecked()
                    }
                    else{
                        elementKey = self.list[(indexPath?.row)!].getKeyID()
                        updatedListElementDescription = editInfo.textFields![0].text!
                        checkedStatus = self.list[(indexPath?.row)!].getchecked()
                    }
                    self.ref = self.db.collection("Lister/\(self.listForSegue.getKeyID())/Elementer").document(elementKey)
                    self.ref.updateData(["Navn" : updatedListElementDescription, "Checked Status": checkedStatus], completion: { (err) in
                        if err != nil {
                            //print("Error editing document: \(err)")
                        } else {
                            //print("Document with ID: \(self.ref!.documentID) edited")
                        }
                    })
                }
            })
            
            editInfo.addTextField { (textField0) in
                //textField0.text = String(self.allBudgets[(indexPath?.row)!].getName())
                if(self.filteredStatus == true){
                    textField0.text = self.sortedList[(indexPath?.row)!].getItemDescription()
                }
                else{
                    textField0.text = self.list[(indexPath?.row)!].getItemDescription()
                }
                textField0.autocapitalizationType = .sentences
            }
            
            editInfo.addAction(cancelAction)
            editInfo.addAction(saveAction)
            self.present(editInfo, animated: true, completion: nil)
        }
    }
    func tilføjNytElement(){
        let alertController = UIAlertController(title: "Tilføj nyt element", message: "", preferredStyle: .alert)
        let action1 = UIAlertAction(title: "Tilføj", style: .default) { (action:UIAlertAction) in
            let elementBeskrivelse = alertController.textFields![0].text!
            let duplicate = self.list.first(where: { $0.getItemDescription() == elementBeskrivelse })
            if(duplicate == nil){
                self.ref = self.db.collection("Lister/\(self.listForSegue.getKeyID())/Elementer").addDocument(data: [
                    "Navn": elementBeskrivelse,
                    "Checked Status": false
                ]) { err in
                    if err != nil {
                        //print("Error adding document: \(err)")
                    } else {
                        //print("Document added with ID: \(self.ref!.documentID)")
                    }
                }
            }
            else{
                let alertController2 = UIAlertController(title: "Fejl", message: "Dette element findes i forvejen!", preferredStyle: .alert)
                let action11 = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
                    
                }
                alertController2.addAction(action11)
                self.present(alertController2, animated: true, completion: nil)
            }
            
        }
        let action3 = UIAlertAction(title: "Tilføj flere", style: .default) { (action:UIAlertAction) in
            let elementBeskrivelse = alertController.textFields![0].text!
            let duplicate = self.list.first(where: { $0.getItemDescription() == elementBeskrivelse })
            if(duplicate == nil){
                self.ref = self.db.collection("Lister/\(self.listForSegue.getKeyID())/Elementer").addDocument(data: [
                    "Navn": elementBeskrivelse,
                    "Checked Status": false
                ]) { err in
                    if err != nil {
                        //print("Error adding document: \(err)")
                    } else {
                        //print("Document added with ID: \(self.ref!.documentID)")
                    }
                }
                self.tilføjNytElement()
            }
            else{
                let alertController2 = UIAlertController(title: "Fejl", message: "Dette element findes i forvejen!", preferredStyle: .alert)
                let action11 = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
                    
                }
                alertController2.addAction(action11)
                self.present(alertController2, animated: true, completion: nil)
            }
            
        }
        let action2 = UIAlertAction(title: "Cancel", style: .cancel) { (action:UIAlertAction) in
            
        }
        alertController.addTextField { (textField0) in
            textField0.placeholder = "Element"
            textField0.autocapitalizationType = .sentences
        }
        alertController.addAction(action1)
        alertController.addAction(action3)
        alertController.addAction(action2)
        self.present(alertController, animated: true, completion: nil)
        tableView1.reloadData()
    }
    @IBAction func filter(sender: AnyObject) {
        if(sortButton.image == filter){
            filteredStatus = true
            self.tableView1.reloadData()
            sortButton.image = filtered
            updateLabel()
        }
        else if(sortButton.image == filtered){
            filteredStatus = false
            self.tableView1.reloadData()
            sortButton.image = filter
            updateLabel()
        }
    }
    func updateLabel(){
        if(filteredStatus == true){
            if(!self.sortedList.isEmpty){
                lastUpdateLabel.text = "\(self.sortedList.count) tilbage"
                lastUpdateLabel.sizeToFit()
            }
            else{
                lastUpdateLabel.text = "Ingen tilbage"
                lastUpdateLabel.sizeToFit()
            }
        }
        else{
            if(!self.list.isEmpty){
                let missing = self.list.count-self.sortedList.count
                lastUpdateLabel.text = "\(missing)/\(self.list.count)"
                lastUpdateLabel.sizeToFit()
            }
            else{
                lastUpdateLabel.text = "Listen er tom"
                lastUpdateLabel.sizeToFit()
            }
        }
    }
}
