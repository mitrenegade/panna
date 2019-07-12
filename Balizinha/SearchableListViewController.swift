import UIKit
import FirebaseCore
import Balizinha
import FirebaseDatabase

// specific to each subclass
class SearchableListViewController: ListViewController {
    @IBOutlet weak var constraintBottomOffset: NSLayoutConstraint!

    // search/filter
    var searchTerm: String?
    @IBOutlet weak var containerSearch: UIView? // may or may not exist
    @IBOutlet weak var inputSearch: UITextField!
    @IBOutlet weak var buttonSearch: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        let userInfo:NSDictionary = notification.userInfo! as NSDictionary
        let keyboardFrame:NSValue = userInfo.value(forKey: UIKeyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRectangle = keyboardFrame.cgRectValue
        let keyboardHeight = keyboardRectangle.height
        constraintBottomOffset.constant = keyboardHeight
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        self.constraintBottomOffset.constant = 0
    }
}

// UITableViewDataSource
extension SearchableListViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < sections.count else { return 0 }
        let sectionStruct = sections[section]
        return sectionStruct.objects.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section < sections.count else { return nil }
        let sectionStruct = sections[section]
        return sectionStruct.name
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        assertionFailure("Must implement cellForRow")
        return UITableViewCell()
    }
}

// MARK: - Search
extension SearchableListViewController {
    @IBAction func didClickSearch(_ sender: Any?) {
        search(for: inputSearch.text)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        didClickSearch(nil)
        return true
    }
    
    func search(for string: String?) {
        print("Search for string \(String(describing: string))")
        
        // filter for search string; if string is nil, uses all players
        searchTerm = string
        var filtered: [FirebaseBaseModel] = objects
        if let currentSearch = searchTerm?.lowercased(), !currentSearch.isEmpty {
            filtered = doFilter(currentSearch)
        }
        
        updateSections(filtered)
        reloadTable()
    }
    
    @objc func updateSections(_ newObjects: [FirebaseBaseModel]) {
        // no op unless the controller needs to have sections
        objects = newObjects
        return
    }

    // to be implemented by subclasses
    func doFilter(_ currentSearch: String) -> [FirebaseBaseModel] {
        return objects
    }
}
