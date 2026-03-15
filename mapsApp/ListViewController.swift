//
//  ListViewController.swift
//  mapsApp
//
//  Created by Elifsu Akkaya on 8.01.2026.
//

import UIKit
import CoreData


class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    @IBOutlet weak var tableView: UITableView!
    var nameArray = [String]()
    var idArray = [UUID]()
    var chooseLName = String()
    var chooseLId: UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(plusClick))
        takeData()

    }
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(takeData), name: NSNotification.Name("yeniSayfaOlusturuldu"), object: nil)
        
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
      
        if editingStyle == .delete {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult> (entityName: "Location")
            let uuidString = idArray[indexPath.row].uuidString
            fetchRequest.predicate = NSPredicate(format: "id == %@",uuidString)
            fetchRequest.returnsObjectsAsFaults = false
            
            do{
                let results =  try context.fetch(fetchRequest)
                if results.count>0{
                    for result in results as! [NSManagedObject] {
                        if let id = result.value(forKey: "id") as? UUID{
                            if id == idArray[indexPath.row]{
                                context.delete(result)
                                idArray.remove(at: indexPath.row)
                                nameArray.remove(at: indexPath.row)
                                self.tableView.reloadData()
                                do{
                                    try context.save()
                                }catch {
                                    
                                }
                                break
                            }
                        }
                    }
                }
            }catch{
                print("make a mistake")
            }
        }
    }

    
    @objc func plusClick(){
        
        chooseLName = ""
        performSegue(withIdentifier: "toMapsVC", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return nameArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell()
        cell.textLabel?.text = nameArray[indexPath.row]
        return cell
    }
    
    @objc func takeData(){
    
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Location") //fetch verileri coredatadan çekmemizi sağlar
        request.returnsObjectsAsFaults = false
        
        do{
            let results = try context.fetch(request)
            
            if results.count > 0{
                
                nameArray.removeAll(keepingCapacity: false)//isim yada id dizisinde boş yer kaplayan şeyler olabileceiği için birden yüklemem yapmamak amacıyla dizilerin içi fordan önce temizlenir
                idArray.removeAll(keepingCapacity: false)
                
                for result in results as! [NSManagedObject]{
                    
                    if let name = result.value(forKey: "name") as? String{
                        nameArray.append(name)
                    }
                    if let id = result.value(forKey: "id") as? UUID{
                        idArray.append(id)
                    }
                }
                tableView.reloadData()//verileri tableViewe yükler
            }
        }catch{
            print("error")
        }
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        chooseLName = nameArray[indexPath.row]
        chooseLId = idArray[indexPath.row]
        performSegue(withIdentifier: "toMapsVC", sender: nil )
    }
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toMapsVC"{
            let destinationVC = segue.destination as! MapsViewController
                destinationVC.chooseName = chooseLName
                destinationVC.chooseId = chooseLId
        }

    }
}
