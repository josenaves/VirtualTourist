//
//  DetailViewController.swift
//  VirtualTourist
//
//  Created by José Naves Moura Neto on 05/05/19.
//  Copyright © 2019 José Naves Moura Neto. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class DetailViewController: UIViewController {
    
    var pinTapped: Pin!
    
    @IBOutlet weak var reloadButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var noImageLabel: UILabel!
    @IBOutlet weak var deleteLabel : UILabel!

    var resultController : NSFetchedResultsController<Photo>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let pin = MKPointAnnotation()
        pin.coordinate = CLLocationCoordinate2DMake(pinTapped.latitude, pinTapped.longitude)
        
        mapView.addAnnotation(pin)
        mapView.setRegion(MKCoordinateRegion(center: pin.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)), animated: true)
        
        navigationItem.rightBarButtonItem = editButtonItem
        navigationItem.title = "🏙 Photo Album"
        deleteLabel.isHidden = true
        
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resultController = nil
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultController()
        
        if (resultController.fetchedObjects?.count)! < 1  {
            reloadImageCollection(nil)
        }
        collectionView.reloadData()
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        deleteLabel.isHidden = !editing
        reloadButton.isHidden = editing
    }
    
    @IBAction func reloadImageCollection(_ sender: Any?) {
        
        deletePhotos()
        
        showNoImageLabel(show: false)
        reloadButtonEnabled(isEnabled: false)
        
        let request = ApiRemoteClient.shared.createRequest(pin: pinTapped)
        
        ApiRemoteClient.shared.makeRequest(request: request) { (result, error) in
            
            guard error == nil else {
                self.showAlertMessage(message: error!)
                self.showNoImageLabel(show: true)
                self.reloadButtonEnabled(isEnabled: true)
                return
            }
            
            guard result!.count > 0 else {
                self.showNoImageLabel(show: true)
                self.reloadButtonEnabled(isEnabled: true)
                return
            }
            
            self.addPhotos(photos: result!)
            self.reloadButtonEnabled(isEnabled: true)
        }
    }
    
    func saveViewContext() {
        try? DataController.shared.viewContext.save()
    }

    fileprivate func addPhotos(photos: NSArray) {
        for _ in 1...15 {
            let randomPhotoIndex = Int(arc4random_uniform(UInt32(photos.count)))
            let photo = photos[randomPhotoIndex] as! [String:AnyObject]
            guard let imageUrl = photo[Constants.FlickrResponseKeys.ImageUrl] as? String else {
                return
            }
            let photoToAdd = Photo(context: DataController.shared.viewContext)
            photoToAdd.pin = pinTapped
            photoToAdd.imageUrl = imageUrl
            saveViewContext()
        }
    }
    
    fileprivate func deletePhotos() {
        for photo in (resultController!.fetchedObjects)! {
            DataController.shared.viewContext.delete(photo)
            saveViewContext()
        }
    }
    
    fileprivate func showNoImageLabel(show: Bool) {
        DispatchQueue.main.async {
            self.noImageLabel.isHidden = !show
        }
    }
    
    fileprivate func reloadButtonEnabled(isEnabled: Bool) {
        DispatchQueue.main.async {
            self.reloadButton.isEnabled = isEnabled
        }
    }
    
    fileprivate func setupFetchedResultController() {

        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        
        fetchRequest.predicate = NSPredicate(format: "pin == %@", pinTapped)
        fetchRequest.sortDescriptors = []
        
        resultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        resultController.delegate = self
        
        do {
            try resultController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
}

extension DetailViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            collectionView.insertItems(at: [newIndexPath!])
            break

        case .delete:
            collectionView.deleteItems(at: [indexPath!])
            break

        case .update:
            collectionView.reloadItems(at: [indexPath!])
            break
            
        default:
            break
        }
    }
}

extension DetailViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return resultController.sections?.count ?? 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return resultController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let photo = resultController.object(at: indexPath)
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoCell
        
        cell.imageView.image = nil
        cell.activityIndicator.startAnimating()
        
        if photo.image == nil {
            
            ApiRemoteClient.shared.downloadImage(imageUrl: photo.imageUrl!) { (image, error) in
                
                guard error == nil else {
                    self.showAlertMessage(message: error!)
                    return
                }
                
                DispatchQueue.main.async {
                    photo.image = image
                    self.saveViewContext()
                    cell.activityIndicator.stopAnimating()
                }
            }
        } else {
            cell.imageView.image = UIImage(data: photo.image!)
            cell.activityIndicator.stopAnimating()
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if isEditing {
            let photo = resultController.object(at: indexPath)
            DataController.shared.viewContext.delete(photo)
            saveViewContext()
        }
    }
}
