//
//  ViewController.swift
//  paginationSwift
//
//  Created by Andrew on 2/9/18.
//  Copyright © 2018 Andrew. All rights reserved.
//

import UIKit
import Firebase
import CoreData
class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {

    let cellId = "cellId"
    
//    var collData = [mainMoStruct]()
    var collData = [Movies]()
    var howMany = 1
    let group = DispatchGroup()
    var actorsNames = [String]()
    var actorsImageData = [Data]()
    
    lazy var myCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        let myColl = UICollectionView(frame: .zero, collectionViewLayout: layout )
        myColl.register(myCustomCell.self, forCellWithReuseIdentifier: cellId)
        myColl.alwaysBounceVertical = true
        myColl.delegate = self
        myColl.dataSource = self
        myColl.translatesAutoresizingMaskIntoConstraints = false
        myColl.backgroundColor = UIColor.white
        return myColl
    }()
    
    let activityIndicator: UIActivityIndicatorView = {
        let activity = UIActivityIndicatorView(activityIndicatorStyle: .white)
        activity.translatesAutoresizingMaskIntoConstraints = false
        return activity
    }()
    
    let effectView: UIVisualEffectView = {
        let effect = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        effect.layer.cornerRadius = 8
        effect.layer.masksToBounds = true
        effect.translatesAutoresizingMaskIntoConstraints = false
        return effect
    }()
    
    let loadingLabel: UILabel = {
        let label = UILabel()
        label.text = "Loading..."
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.white
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textAlignment = .center
        return label
    }()
    
    var manageObjectContext: NSManagedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(myCollectionView)
//        readFileFromProject()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Refresh", style: .done, target: self, action: #selector(refreshAll))
        
        manageObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        addConstraints()
        loadDataMovies()
    }
    let moviesDataFetch: NSFetchRequest<Movies> = Movies.fetchRequest()
    func loadDataMovies(){
        do{
            collData = try manageObjectContext.fetch(moviesDataFetch)
            if collData.count == 0{
                fetchDataFromFirebase()
            }
        }catch let err{
            print(err.localizedDescription)
        }
    }
    
    @objc func refreshAll(){
//        let request = NSBatchDeleteRequest(fetchRequest: moviesDataFetch as! NSFetchRequest<NSFetchRequestResult>)
        howMany = 1
        do{
            
            let objects = try manageObjectContext.fetch(moviesDataFetch)
            if objects != nil{
                for object in objects{
                    manageObjectContext.delete(object)
                }
            }
        }catch let err{
            print(err.localizedDescription)
        }
        
        collData.removeAll()
        DispatchQueue.main.async {
            self.myCollectionView.reloadData()
        }
        fetchDataFromFirebase()
    }
    
    func readFileFromProject(){
        guard let pathExist = Bundle.main.path(forResource: "file", ofType: "json") else { return }
        if FileManager.default.fileExists(atPath: pathExist){
            
            do{
                let jsonData = try Data(contentsOf: URL(fileURLWithPath: pathExist), options: .alwaysMapped)
//                let dictData = try JSONDecoder().decode(mainStruct.self, from: jsonData as Data)
                let dictData = try JSONSerialization.data(withJSONObject: jsonData, options: .sortedKeys) as! NSDictionary
                print(dictData)
            }catch let err {
                print(err.localizedDescription)
            }
            
        }
    }
    
    func fetchDataFromFirebase(){
        let ref = Firestore.firestore().collection("movies")
        ref.getDocuments { (snap, err) in
            if err != nil{
                print(err?.localizedDescription)
                return
            }
            
            guard let documents = snap?.documents else { return }
            let lastElem = self.collData.count
            for (index,elem) in documents.enumerated(){
                if index >= lastElem && index <= self.howMany{
                    let data = elem.data()
                    let movieKey = elem.documentID
//                    let dict = mainStruct(dict: data)
//                    self.collData.append(dict)
                    let movieItem = Movies(context: self.manageObjectContext)
                    movieItem.name = data["name"] as? String
                    guard let profileImageName = data["profileImage"] as? String else { return }
                    let imageData = self.downloadImage(url: profileImageName)
                    movieItem.profileImage = imageData as Data
                    
                    ref.document(movieKey).collection("moviesActors").getDocuments(completion: { (snapshot, err2) in
                        if err2 != nil{
                            print(err2?.localizedDescription)
                            return
                        }
                        
                        guard let actorsDocs = snapshot?.documents else { return }
                        
                        for (_,elem2) in actorsDocs.enumerated(){
                            let actorData = elem2.data()
                            let actorName = actorData["actorName"] as! String
                            let actorImage = actorData["actorImage"] as! String
                            let actorImageData = self.downloadImage(url: actorImage)
                            self.actorsImageData.append(actorImageData)
                            self.actorsNames.append(actorName)
                        }
                        let movieInfoItem = MoviesInfo(context: self.manageObjectContext)
                        movieInfoItem.actors = self.actorsNames as NSObject
                        movieInfoItem.actorsImages = self.actorsImageData as NSObject 
                        movieInfoItem.relationshipForMovies = movieItem
                        self.actorsNames.removeAll()
                        self.actorsImageData.removeAll()
                    })
//                    self.group.wait()
                    
                    do{
                        try self.manageObjectContext.save()
                        self.loadDataMovies()
                    }catch{
                        print("Could not save data \(error.localizedDescription)")
                    }
                    DispatchQueue.main.async {
                        self.myCollectionView.reloadData()
                        self.activityIndicator.stopAnimating()
                        self.effectView.removeFromSuperview()
                        self.loadingLabel.removeFromSuperview()
                        
                    }
                }
            }
        }
    }
    
    func downloadImage(url: String) -> Data{
        let url = URL(string: url)
        var imageDataVar = Data()
        group.enter()
        URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
            
            if error != nil {
                print(error ?? "")
                return
            }
            if let imageData = data{
                imageDataVar = imageData
                self.group.leave()
            }
            
        }).resume()
        group.wait()
        return imageDataVar
    }
    
    func addConstraints(){
        myCollectionView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        myCollectionView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        myCollectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        myCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! myCustomCell
        let cellData = collData[indexPath.row]
        cell.profileImageVIew.image = UIImage(data: cellData.profileImage!)
//        if let imageExist = cellData.profileImage{
//            cell.profileImageVIew.loadImageUsingCacheString(urlString: imageExist)
//        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width , height: view.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let infoPage = moviesDisplayPageInfo()
        infoPage.info = collData[indexPath.row]
        self.navigationController?.pushViewController(infoPage, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let lastItem = collData.count - 1
        howMany = collData.count
        if lastItem == indexPath.row{
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                self.fetchDataFromFirebase()
                self.addActivity()
                self.activityIndicator.startAnimating()
            })
        }
    }
    
    @objc func addActivity(){
        self.view.addSubview(effectView)
        effectView.contentView.addSubview(activityIndicator)
        effectView.contentView.addSubview(loadingLabel)
        
        effectView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        effectView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        effectView.heightAnchor.constraint(equalToConstant: 46).isActive = true
        effectView.widthAnchor.constraint(equalToConstant: 150).isActive = true
        
        activityIndicator.leftAnchor.constraint(equalTo: effectView.leftAnchor,constant: 5).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: effectView.centerYAnchor).isActive = true
//        activityIndicator.heightAnchor.constraint(equalToConstant: 46).isActive = true
//        activityIndicator.widthAnchor.constraint(equalToConstant: 46).isActive = true
        
        
        loadingLabel.leftAnchor.constraint(equalTo: effectView.leftAnchor, constant: 15).isActive = true
        loadingLabel.centerYAnchor.constraint(equalTo: effectView.centerYAnchor).isActive = true
        loadingLabel.heightAnchor.constraint(equalToConstant: 46).isActive = true
        loadingLabel.widthAnchor.constraint(equalToConstant: 150).isActive = true
    }
}
class myCustomCell: UICollectionViewCell {
    
    
    let profileImageVIew: UIImageView = {
        let image = UIImage(named: "")
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(profileImageVIew)
        addConstraints()
    }
    
    func addConstraints(){
        profileImageVIew.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        profileImageVIew.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        profileImageVIew.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        profileImageVIew.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

