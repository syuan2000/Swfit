//
//  DocumentsViewController.swift
//  Documents Core Data
//
//  Created by Eva Li on 2/15/21

// UISearchController reference:
//www.raywenderlich.com/4363809-uisearchcontroller-tutorial-getting-started

import UIKit
import CoreData

class DocumentsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    @IBOutlet weak var documentsTableView: UITableView!
    let dateFormatter = DateFormatter()
    var documents = [Document]()
    var searchController : UISearchController?
    var selectedSearchScope = SearchScope.all

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Documents"

        documentsTableView.backgroundColor=UIColor(red: 245/255, green: 245/255, blue: 244/255, alpha: 1)

        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        
        searchController = UISearchController(searchResultsController: nil)
        
        searchController?.searchResultsUpdater = self
        searchController?.obscuresBackgroundDuringPresentation = false
        searchController?.searchBar.placeholder = "Search Documents"
        
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        searchController?.searchBar.scopeButtonTitles = SearchScope.titles
        searchController?.searchBar.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchDocuments(searchString: "")
    }
    
    func alertNotifyUser(message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel) {
            (alertAction) -> Void in
            print("OK selected")
        })
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func fetchDocuments(searchString: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Document> = Document.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)] // order results by document name ascending
        
        do {
            if (searchString != "") {
                switch (selectedSearchScope) {
                case .all:
                    fetchRequest.predicate = NSPredicate(format: "name contains[c] %@ OR content contains[c] %@", searchString, searchString)
                case .name:
                    fetchRequest.predicate = NSPredicate(format: "name contains[c] %@", searchString)
                case .content:
                    fetchRequest.predicate = NSPredicate(format: "content contains[c] %@", searchString)
                }
            }
            documents = try managedContext.fetch(fetchRequest)
            documentsTableView.reloadData()
        } catch {
            print("Fetch could not be performed")
        }
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        if let searchString = searchController.searchBar.text {
            fetchDocuments(searchString: searchString)
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        selectedSearchScope = SearchScope.scopes[selectedScope]
        if let searchString = searchController?.searchBar.text {
            fetchDocuments(searchString: searchString)
        }
    }
    
    func deleteDocument(at indexPath: IndexPath) {
        let document = documents[indexPath.row]
        
        if let managedObjectContext = document.managedObjectContext {
            managedObjectContext.delete(document)
            
            do {
                try managedObjectContext.save()
                self.documents.remove(at: indexPath.row)
                documentsTableView.deleteRows(at: [indexPath], with: .automatic)
            } catch {
                alertNotifyUser(message: "Delete failed.")
                documentsTableView.reloadData()
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return documents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "documentCell", for: indexPath)
        cell.backgroundColor = UIColor.clear
        if let cell = cell as? DocumentTableViewCell {
            
            let document = documents[indexPath.row]
            cell.nameLabel.text = document.name
            cell.sizeLabel.text = String(document.size) + " bytes"
            
            if let modifiedDate = document.modifiedDate {
                cell.modifiedLabel.text = dateFormatter.string(from: modifiedDate)
            } else {
                cell.modifiedLabel.text = "unknown"
            }
        }
        
        return cell
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? DocumentViewController,
           let segueIdentifier = segue.identifier, segueIdentifier == "existingDocument",
           let row = documentsTableView.indexPathForSelectedRow?.row {
                destination.document = documents[row]
        }
    }
    

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteDocument(at: indexPath)
        }
    }
}



