//
//  PhotoAlbumViewContoller.swift
//  VirtualTourist
//
//  Created by Shahad on 18/04/1441 AH.
//  Copyright © 1441 Udacity. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MapKit

class PhotoAlbumViewContoller : UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var button: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    
    
    var dataController : DataController!
    
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var pin: Pin!
    var pageNumber = 1
    var isDeletingEverything = false
    
    var context: NSManagedObjectContext {
        return DataController.sharedInstance.viewContext
    }
    
    var doWeHavePhotos: Bool {
        return (fetchedResultsController.fetchedObjects?.count ?? 0) != 0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
        activityIndicator.stopAnimating()
        collectionView.delegate = self
        collectionView.dataSource = self
        
    }
    
    func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", pin)
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
            if doWeHavePhotos {
                updateUI(processing: false)
            } else {
                buttomButtonTapped(self)
            }
            
        } catch {
            fatalError("The fetch could not be performd: \(error.localizedDescription)")
        }
    }
    
    @IBAction func buttomButtonTapped(_ sender: Any) {
        updateUI(processing: true)
        if doWeHavePhotos {
            isDeletingEverything = true
            for photo in fetchedResultsController.fetchedObjects! {
                context.delete(photo)
            }
            try? context.save()
            isDeletingEverything = false
        }
        
        FlickrAPI.getPhotosUrls(with: pin.coordinate, pageNumber: pageNumber) { (urls, error, errorMessage) in
            DispatchQueue.main.async {
                
                self.updateUI(processing: false)
                
                guard (error == nil) && (errorMessage == nil) else {
                    self.alert(title: "Error",
                               message: error?.localizedDescription ?? errorMessage!)
                    return
                }
                
                guard let urls = urls, !urls.isEmpty else {
                    self.label.text = "This pin has no images"
                    return
                }
                
                for url in urls {
                    let photo = Photo(context: self.context)
                    photo.imageURL = url
                    photo.pin = self.pin
                }
                
                try? self.context.save()
            }
        }
        pageNumber += 1
    }
    
    func updateUI(processing: Bool) {
        collectionView.isUserInteractionEnabled = !processing
        
        processing ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
        button.title = processing ? "" : "New Collection"
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        collectionView.reloadData()
    }
    
    // MARK: UICollectionViewDataSource & UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        let photo = fetchedResultsController.object(at: indexPath)
        
        cell.imageView.setPhoto(photo)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photo = fetchedResultsController.object(at: indexPath)
        context.delete(photo)
        try? context.save()
    }
    
    // MARK: UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.width-20) / 3
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    // MARK: NSFetchedResultsControllerDelegate
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        if let indexPath = indexPath, type == .delete && !isDeletingEverything {
            collectionView.deleteItems(at: [indexPath])
            return
        }
        
        if let indexPath = indexPath, type == .insert {
            collectionView.insertItems(at: [indexPath])
            return
        }
        
        if let newIndexPath = newIndexPath, let oldIndexPath = indexPath, type == .move {
            collectionView.moveItem(at: oldIndexPath, to: newIndexPath)
            return
        }
        
        if type != .update {
            collectionView.reloadData()
        }
    }
}


    





