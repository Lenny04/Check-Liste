//
//  OversigtViewController.swift
//  Check Liste
//
//  Created by linoj ravindran on 15/08/2018.
//  Copyright © 2018 linoj ravindran. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseAuth
import FirebaseFirestore
class OversigtViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var lists = [List]()
    var currentIndex = 0
    var refreshControl: UIRefreshControl!
    @IBOutlet weak var tableView: UITableView!
    var ref: DocumentReference!
    lazy var db = Firestore.firestore()
    var quoteListenerLists: ListenerRegistration!
    override func viewDidAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        tableView.addGestureRecognizer(longPressRecognizer)
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Refreshing")
        refreshControl.addTarget(self, action: #selector(OversigtViewController.refresh), for:.valueChanged)
        tableView.addSubview(refreshControl)
        let settings = db.settings
        settings.areTimestampsInSnapshotsEnabled = true
        db.settings = settings
        quoteListenerLists = db.collection("Lister").addSnapshotListener { (querySnapshot, err) in
            if err != nil {
                //print("Error getting documents: \(err)")
            } else {
                querySnapshot?.documentChanges.forEach { diff in
                    if (diff.type == .added){
                        self.lists.append(List(listName: "", keyID: diff.document.documentID))
                        let value1 = diff.document.data() as NSDictionary
                        for (key, value) in value1 {
                            let notenu = key as! String
                            switch notenu{
                            case "Navn":
                                self.lists[self.lists.count-1].setListName(a: value as! String)
                                break
                            default:
                                self.tableView.reloadData()
                            }
                        }
                        //print("Document added in firestore")
                        self.tableView.reloadData()
                    }
                    if(diff.type == .modified) {
                        //print("Modified the document in firestore")
                        let value1 = diff.document.data() as NSDictionary
                        for (key, value) in value1 {
                            let notenu = key as! String
                            if(notenu == "Navn"){
                                self.lists[self.currentIndex].setListName(a: value as! String)
                            }
                        }
                        self.lists.sort {$0.getListName() < $1.getListName()}
                        self.tableView.reloadData()
                    }
                    if(diff.type == .removed) {
                        //print("Document removed from firestore")
                        self.tableView.reloadData()
                    }
                    
                }
                self.lists.sort {$0.getListName() < $1.getListName()}
            }
        }
        self.tableView.reloadData()
}
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        quoteListenerLists.remove()
    }
    @IBAction func tilføjKnap(sender: AnyObject) {
        let alertController = UIAlertController(title: "Tilføj ny liste", message: "", preferredStyle: .alert)
        let action1 = UIAlertAction(title: "Tilføj", style: .default) { (action:UIAlertAction) in
            let listNavn = alertController.textFields![0].text!
            let duplicate = self.lists.first(where: { $0.getListName() == listNavn })
            if(duplicate == nil){
                self.ref = self.db.collection("Lister").addDocument(data: [
                    "Navn": listNavn,
                    "Elementer": ""
                ]) { err in
                    if err != nil {
                        //print("Error adding document: \(err)")
                    } else {
                        //print("Document added with ID: \(self.ref!.documentID)")
                    }
                }
            }
            else{
                let alertController2 = UIAlertController(title: "Fejl", message: "Denne liste findes i forvejen!", preferredStyle: .alert)
                let action11 = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
                    
                }
                alertController2.addAction(action11)
                self.present(alertController2, animated: true, completion: nil)
            }
        }
        let action2 = UIAlertAction(title: "Cancel", style: .cancel) { (action:UIAlertAction) in
            
        }
        alertController.addTextField { (textField0) in
            textField0.placeholder = "Navn"
            textField0.autocapitalizationType = .sentences
        }
        alertController.addAction(action1)
        alertController.addAction(action2)
        self.present(alertController, animated: true, completion: nil)
        tableView.reloadData()
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.lists.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell2", for: indexPath) as! CheckListListsCell
        cell.label.text = self.lists[indexPath.row].getListName()
        return cell
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
    }
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let deleteRowAction = UITableViewRowAction(style: UITableViewRowAction.Style.default, title: "Slet", handler:{action, indexpath in
            let listItemKey = self.lists[indexPath.row].getKeyID()
            self.db.collection("Lister").document(listItemKey).delete() { err in
                if err != nil {
                    //print("Error removing document: \(err)")
                } else {
                    //print("Document successfully removed!")
                }
            }
            self.lists.remove(at: indexPath.row)
            self.tableView.reloadData()
        })
        return [deleteRowAction]
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCell = tableView.cellForRow(at: indexPath as IndexPath)!
        performSegue(withIdentifier: "toListItem", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    @objc func refresh() {
        tableView.reloadData()
        refreshControl.endRefreshing()
    }
    @objc func longPress(_ guesture: UILongPressGestureRecognizer) {
        if guesture.state == UIGestureRecognizer.State.began {
            let point = guesture.location(in: tableView)
            let indexPath = tableView.indexPathForRow(at: point)
            currentIndex = indexPath!.row
            let editInfo = UIAlertController(title: nil, message: "List Info", preferredStyle: UIAlertController.Style.alert)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: { (action) -> Void in
                
            })
            
            let saveAction = UIAlertAction(title: "Gem", style: .default, handler: { (action) -> Void in
                if(!(editInfo.textFields![0].text?.isEmpty)!){
                    let listKey = self.lists[(indexPath?.row)!].getKeyID()
                    let updatedListName = editInfo.textFields![0].text!
                    self.ref = self.db.collection("Lister").document(listKey)
                    self.ref.updateData(["Navn" : updatedListName], completion: { (err) in
                        if err != nil {
                            //print("Error editing document: \(err)")
                        } else {
                            //print("Document with ID: \(self.ref!.documentID) edited")
                        }
                    })
                }
                self.tableView.reloadData()
            })
            
            editInfo.addTextField { (textField0) in
                textField0.text = self.lists[(indexPath?.row)!].getListName()
                textField0.autocapitalizationType = .sentences
            }
            
            editInfo.addAction(cancelAction)
            editInfo.addAction(saveAction)
            self.present(editInfo, animated: true, completion: nil)
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "toListItem") {
            if let destinationVC = segue.destination as? ViewController{
                currentIndex = (tableView.indexPathForSelectedRow?.row)!
                destinationVC.listForSegue.setListName(a: self.lists[currentIndex].getListName())
                destinationVC.listForSegue.setKeyID(c: self.lists[currentIndex].getKeyID())
            }
        }
    }
}
