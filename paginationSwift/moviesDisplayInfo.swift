//
//  moviesDisplayInfo.swift
//  paginationSwift
//
//  Created by Andrew on 2/10/18.
//  Copyright © 2018 Andrew. All rights reserved.
//

import UIKit

class moviesDisplayPageInfo: UIViewController,UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    let cellId = "cellId"
    
    var info: Movies?{
        didSet{
            navigationItem.title = info?.name
            let allActors = info?.relationshipForMoviesInfo?.allObjects as! [MoviesInfo]
            for obj in allActors {
                
                for actorName in obj.actors as! [String]{
                    self.actorArrInfoNames.append(actorName)
                }
                for actorImage in obj.actorsImages as! [Data]{
                    self.actorArrInfoImages.append(actorImage)
                }
            }
        }
    }
    
    lazy var myCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        let myColl = UICollectionView(frame: .zero, collectionViewLayout: layout )
        myColl.register(myCustomActorCell.self, forCellWithReuseIdentifier: cellId)
        myColl.delegate = self
        myColl.dataSource = self
        myColl.showsHorizontalScrollIndicator = false
        myColl.translatesAutoresizingMaskIntoConstraints = false
        myColl.backgroundColor = UIColor.white
        return myColl
    }()
    
    var actorArrInfoNames = [String]()
    var actorArrInfoImages = [Data]()
    
    override func viewDidLoad() {
        self.edgesForExtendedLayout = []
        super.viewDidLoad()
        view.addSubview(myCollectionView)
        view.backgroundColor = UIColor.white
        addConstraints()
    }
    
    func addConstraints(){
        myCollectionView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        myCollectionView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        myCollectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        myCollectionView.heightAnchor.constraint(equalToConstant: 230).isActive = true
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        return actorArrInfoNames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! myCustomActorCell
//        cell.backgroundColor = UIColor.red
        let actorsImages = actorArrInfoImages[indexPath.row]
        let actorsName = actorArrInfoNames[indexPath.row]
        cell.profileImageVIew.image = UIImage(data: actorsImages)
        cell.actorName.text = actorsName
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 150 , height: 200)
    }
    
}


class myCustomActorCell: UICollectionViewCell {
    
    
    let profileImageVIew: UIImageView = {
        let image = UIImage(named: "")
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
//        imageView.layer.cornerRadius =
//        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    let actorName: UILabel = {
        let label = UILabel()
        label.text = "Amza"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(profileImageVIew)
        addSubview(actorName)
        addConstraints()
    }
    
    func addConstraints(){
        profileImageVIew.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        profileImageVIew.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        profileImageVIew.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        profileImageVIew.bottomAnchor.constraint(equalTo: self.bottomAnchor,constant: -30).isActive = true
        
        actorName.bottomAnchor.constraint(equalTo: self.bottomAnchor,constant: -5).isActive = true
        actorName.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
