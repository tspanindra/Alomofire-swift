//
//  PhotoBrowserCollectionViewController.swift
//  Photomania
//
//  Created by Essan Parto on 2014-08-20.
//  Copyright (c) 2014 Essan Parto. All rights reserved.
//

import UIKit
import Alamofire

class PhotoBrowserCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
  var photos = NSMutableOrderedSet()
  
  let refreshControl = UIRefreshControl()
  var populatingPhotos = false
  var currentPage = 1

  let PhotoBrowserCellIdentifier = "PhotoBrowserCell"
  let PhotoBrowserFooterViewIdentifier = "PhotoBrowserFooterView"
  
  // MARK: Life-cycle
/*
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupView()

    Alamofire.request(.GET, "https://api.500px.com/v1/photos",parameters: ["consumer_key": "YferGVsKlVUoeU83GlfzGr6UTNoN4MvjRX3AbVEd"]).responseJSON() {
        (_, _, data, _) in
        let photoInfos = (data!.valueForKey("photos") as! [NSDictionary]).filter({
            ($0["nsfw"] as! Bool) == false
        }).map {
            PhotoInfo(id: $0["id"] as! Int, url: $0["image_url"] as! String)
        }

        self.photos.addObjectsFromArray(photoInfos)
        
        self.collectionView!.reloadData()
    }
  }*/

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()

        populatePhotos()
    }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  // MARK: CollectionView
  
  override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return photos.count
  }
  
  override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(PhotoBrowserCellIdentifier, forIndexPath: indexPath) as! PhotoBrowserCollectionViewCell

    let imageURL = (photos.objectAtIndex(indexPath.row) as! PhotoInfo).url

    cell.imageView.image = nil
    cell.request?.cancel()

    cell.request = Alamofire.request(.GET, imageURL).responseImage() {
        (request, _, image, error) in
        if error == nil && image != nil {
            cell.imageView.image = image
        }
    }
    
    return cell
  }
  
  override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
    return collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: PhotoBrowserFooterViewIdentifier, forIndexPath: indexPath) as! UICollectionReusableView
  }
  
  override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    performSegueWithIdentifier("ShowPhoto", sender: (self.photos.objectAtIndex(indexPath.item) as! PhotoInfo).id)
  }
  
  // MARK: Helper
  
  func setupView() {
    navigationController?.setNavigationBarHidden(false, animated: true)
    
    let layout = UICollectionViewFlowLayout()
    let itemWidth = (view.bounds.size.width - 2) / 3
    layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
    layout.minimumInteritemSpacing = 1.0
    layout.minimumLineSpacing = 1.0
    layout.footerReferenceSize = CGSize(width: collectionView!.bounds.size.width, height: 100.0)
    
    collectionView!.collectionViewLayout = layout
    
    navigationItem.title = "Featured"
    
    collectionView!.registerClass(PhotoBrowserCollectionViewCell.classForCoder(), forCellWithReuseIdentifier: PhotoBrowserCellIdentifier)
    collectionView!.registerClass(PhotoBrowserCollectionViewLoadingCell.classForCoder(), forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: PhotoBrowserFooterViewIdentifier)
    
    refreshControl.tintColor = UIColor.whiteColor()
    refreshControl.addTarget(self, action: "handleRefresh", forControlEvents: .ValueChanged)
    collectionView!.addSubview(refreshControl)
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "ShowPhoto" {
      (segue.destinationViewController as! PhotoViewerViewController).photoID = sender!.integerValue
      (segue.destinationViewController as! PhotoViewerViewController).hidesBottomBarWhenPushed = true
    }
  }

    // 1
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView.contentOffset.y + view.frame.size.height > scrollView.contentSize.height * 0.8 {
            populatePhotos()
        }
    }

    func populatePhotos() {
        // 2
        if populatingPhotos {
            return
        }

        populatingPhotos = true

        // 3
        Alamofire.request(Five100px.Router.PopularPhotos(self.currentPage)).responseJSON() {
            (_, _, JSON, error) in

            if error == nil {
                // 4
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
                    // 5, 6, 7
                    let photoInfos = ((JSON as! NSDictionary).valueForKey("photos") as! [NSDictionary]).filter({ ($0["nsfw"] as! Bool) == false }).map { PhotoInfo(id: $0["id"] as! Int, url: $0["image_url"] as! String) }

                    // 8
                    let lastItem = self.photos.count
                    // 9
                    self.photos.addObjectsFromArray(photoInfos)

                    // 10
                    let indexPaths = (lastItem..<self.photos.count).map { NSIndexPath(forItem: $0, inSection: 0) }
                    
                    // 11
                    dispatch_async(dispatch_get_main_queue()) {
                        self.collectionView!.insertItemsAtIndexPaths(indexPaths)
                    }
                    
                    self.currentPage++
                }
            }
            self.populatingPhotos = false
        }
    }
    
    func handleRefresh() {
        refreshControl.beginRefreshing()

        self.photos.removeAllObjects()
        self.currentPage = 1

        self.collectionView!.reloadData()

        refreshControl.endRefreshing()
        
        populatePhotos()
    }
}

class PhotoBrowserCollectionViewCell: UICollectionViewCell {
  let imageView = UIImageView()
  var request: Alamofire.Request?

  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    backgroundColor = UIColor(white: 0.1, alpha: 1.0)
    
    imageView.frame = bounds
    addSubview(imageView)
  }
}

class PhotoBrowserCollectionViewLoadingCell: UICollectionReusableView {
  let spinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    spinner.startAnimating()
    spinner.center = self.center
    addSubview(spinner)
  }
}
