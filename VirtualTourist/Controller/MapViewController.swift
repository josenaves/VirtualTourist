//
//  ViewController.swift
//  VirtualTourist
//
//  Created by José Naves Moura Neto on 24/03/19.
//  Copyright © 2019 José Naves Moura Neto. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var labelDelete: UILabel!
    
    var resultController: NSFetchedResultsController<Pin>!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        labelDelete.isHidden = true
        navigationItem.rightBarButtonItem = editButtonItem
        
        addGesture()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resultController = nil
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupFetchedResultController()
        setMapRegion()
        setupMarkers()
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        labelDelete.isHidden = !editing
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? DetailViewController {
            let pin = sender as! Pin
            vc.pinTapped = pin
        }
    }

    fileprivate func setupFetchedResultController() {
        
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        fetchRequest.sortDescriptors = []
        resultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        do {
            try resultController.performFetch()
        } catch {
            fatalError("Fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    fileprivate func setupMarkers() {
        let pins = resultController.fetchedObjects
        mapView.removeAnnotations(mapView.annotations)
        
        for p in pins! {
            addMarkerToMap(coordinate: CLLocationCoordinate2D(latitude: p.latitude, longitude: p.longitude))
        }
    }
    
    fileprivate func setMapRegion() {
        if let mapRegion = UserDefaults.standard.dictionary(forKey: "mapRegion") {
            let center = CLLocationCoordinate2DMake(mapRegion["lat"] as! Double, mapRegion["long"] as! Double)
            let span = MKCoordinateSpan(latitudeDelta: mapRegion["latDelta"] as! Double, longitudeDelta: mapRegion["longDelta"] as! Double)
            let region = MKCoordinateRegion(center: center, span: span)
            mapView.setRegion(region, animated: true)
        }
    }
}

extension MapViewController {
    
    private func addGesture() {
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(addMarker(gesture:)))
        gestureRecognizer.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(gestureRecognizer)
    }
    
    @objc func addMarker(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let pinLocation = gesture.location(in: mapView)
            let pinCoordinate = mapView.convert(pinLocation, toCoordinateFrom: mapView)
            addMarkerToMap(coordinate: pinCoordinate)
            addPin(coordinate: pinCoordinate)
        }
    }
    
    func addMarkerToMap(coordinate: CLLocationCoordinate2D) {
        let pin = MKPointAnnotation()
        pin.coordinate = coordinate
        mapView.addAnnotation(pin)
    }
    
    func addPin(coordinate: CLLocationCoordinate2D) {
        let pinToAdd = Pin(context: DataController.shared.viewContext)
        pinToAdd.longitude = coordinate.longitude
        pinToAdd.latitude = coordinate.latitude
        saveViewContext()
    }
    
    func getPin(latitude: Double, longitude: Double) -> Pin? {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "longitude == %lf AND latitude == %lf", longitude, latitude)
        
        guard let pin = (try? DataController.shared.viewContext.fetch(fetchRequest))!.first else {
            return nil
        }
        return pin
    }
    
    func saveViewContext() {
        try? DataController.shared.viewContext.save()
    }
}

extension MapViewController : MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: "pin") as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
            pinView?.animatesDrop = true
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let pin = getPin(latitude: (view.annotation?.coordinate.latitude)!, longitude: (view.annotation?.coordinate.longitude)!) else {
            self.showAlertMessage(message: "Pin not found in database")
            return
        }
        
        if isEditing {
            DataController.shared.viewContext.delete(pin)
            saveViewContext()
            mapView.removeAnnotation(view.annotation!)
        } else {
            performSegue(withIdentifier: "detailView", sender: pin)
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let defaults = UserDefaults.standard
        let locationData = ["lat":mapView.centerCoordinate.latitude
            , "long":mapView.centerCoordinate.longitude
            , "latDelta":mapView.region.span.latitudeDelta
            , "longDelta":mapView.region.span.longitudeDelta]
        defaults.set(locationData, forKey: "mapRegion")
    }
}

