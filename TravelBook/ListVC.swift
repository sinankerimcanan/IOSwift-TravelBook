//
//  ListVC.swift
//  TravelBook
//
//  Created by Sinan on 12.03.2023.
//

import UIKit
import CoreData

class ListVC: UIViewController,UITableViewDelegate,UITableViewDataSource {


    @IBOutlet weak var tableView: UITableView!
    
    var titleArray = [String]()
    var idArray = [UUID]()
    
    var choosenTitle = ""
    var choosenId : UUID?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.topItem?.rightBarButtonItem  = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addButtonClicked))
        
        tableView.delegate  = self
        tableView.dataSource = self
        
        getData()
    }
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name(rawValue: "newData"), object: nil)
    }
    
    
    @objc func getData(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Yerler")
        request.returnsObjectsAsFaults = false
        
        do{
            let results = try context.fetch(request)
            
            if results.count > 0 {
                
                self.titleArray.removeAll(keepingCapacity: false)
                self.idArray.removeAll(keepingCapacity: false)
                
                
                for result in results as! [NSManagedObject]{
                    if let title = result.value(forKey: "title") as? String{
                        self.titleArray.append(title)
                    }
                    if let id = result.value(forKey: "id") as? UUID{
                        self.idArray.append(id)
                    }
                    tableView.reloadData()
                }
            }
        }
        catch{
            print("Error")
        }
    }
    
    
    @objc func addButtonClicked(){
        choosenTitle = ""
        performSegue(withIdentifier: "toListVC", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = titleArray[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titleArray.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        choosenTitle = titleArray[indexPath.row]
        choosenId = idArray[indexPath.row]
        performSegue(withIdentifier: "toListVC", sender: nil)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toListVC"{
            let desVC = segue.destination as! ViewController
            desVC.selectedTitle = choosenTitle
            desVC.selectedId = choosenId
        }
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete{
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchReq = NSFetchRequest<NSFetchRequestResult>(entityName: "Yerler")
            fetchReq.returnsObjectsAsFaults = false
            
            do{
                let results = try context.fetch(fetchReq)
                if results.count > 0 {
                    for result in results as! [NSManagedObject]{
                        if let id = result.value(forKey: "id") as? UUID{
                            if id == idArray[indexPath.row]{
                                context.delete(result)
                                idArray.remove(at: indexPath.row)
                                titleArray.remove(at: indexPath.row)
                                self.tableView.reloadData()
                                
                                do{
                                    try context.save()
                                }
                                catch{
                                    print("error")
                                }
                                break
                            }
                        }
                    }
                }
            }
            catch{
                print("error")
            }
            
        }
    }
}
