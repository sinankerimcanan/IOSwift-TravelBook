//
//  ViewController.swift
//  TravelBook
//
//  Created by Sinan on 11.03.2023.
//
import MapKit
import UIKit
import CoreLocation
import CoreData

class ViewController: UIViewController ,MKMapViewDelegate , CLLocationManagerDelegate {
    
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var Button: UIButton!
    @IBOutlet weak var noteText: UITextField!
    @IBOutlet weak var nameText: UITextField!
    
    var locationManager = CLLocationManager()
    
    var choosenLatitude = Double()
    var choosenLongitude = Double()
    
    var selectedTitle = ""
    var selectedId : UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        mapView.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // Kendi konum icin sapma miktari
        locationManager.requestWhenInUseAuthorization() // Izin isteme
        locationManager.startUpdatingLocation()
        //Basili tutma aktiflestirme
        let gestureRec = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRec: )))
        
        gestureRec.minimumPressDuration = 3
        mapView.addGestureRecognizer(gestureRec)
        
        if selectedTitle != "" {
            //CoreData
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchReq = NSFetchRequest<NSFetchRequestResult>(entityName: "Yerler")
            let idString = selectedId!.uuidString
            fetchReq.predicate = NSPredicate(format: "id  = %@", idString)
            fetchReq.returnsObjectsAsFaults = false
            
            do{
                let results = try context.fetch(fetchReq)
                if results.count > 0 {
                    for result in results as! [NSManagedObject]{
                        if let title = result.value(forKey: "title") as? String{
                            annotationTitle = title
                            if let subtitle = result.value(forKey: "subtitle") as? String{
                                annotationSubtitle = subtitle
                                if let latitude = result.value(forKey: "latitude") as? Double{
                                    annotationLatitude = latitude
                                    if let longitude = result.value(forKey: "longitude") as? Double{
                                        annotationLongitude = longitude
                                        
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationTitle
                                        annotation.subtitle = annotationSubtitle
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                        annotation.coordinate = coordinate
                                        
                                        mapView.addAnnotation(annotation)
                                        nameText.text = annotationTitle
                                        noteText.text = annotationSubtitle
                                        locationManager.stopUpdatingLocation()
                                        
                                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                        
                                    }
                                }
                            }
                        }
                    }
                }
            }catch{
                print("error")
            }
        }
        else{
            //Add New Data
            nameText.text = ""
            noteText.text = ""
        }
    }
    
    @objc func chooseLocation(gestureRec : UILongPressGestureRecognizer){
        if gestureRec.state == .began{
            //parmak ile sec ilen bolgenin kordinatlarini alama
            let touchedPoint = gestureRec.location(in: self.mapView)
            let touchedKordinat = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
            
            choosenLatitude = touchedKordinat.latitude
            choosenLongitude = touchedKordinat.longitude
            
            //KOnulcak olan Pin
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedKordinat
            annotation.title = nameText.text
            annotation.subtitle = noteText.text
            self.mapView.addAnnotation(annotation)
        }
    }
    @IBAction func saveButton(_ sender: Any) {
        let appDelegent = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegent.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Yerler", into: context)
        
        newPlace.setValue(nameText.text, forKey: "title")
        newPlace.setValue(noteText.text, forKey: "subtitle")
        newPlace.setValue(choosenLatitude, forKey: "latitude")
        newPlace.setValue(choosenLongitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        do{
            try context.save()
            print("success")
        }catch{
            print("error")
        }
        NotificationCenter.default.post(name: NSNotification.Name("newData"), object: nil)
        self.navigationController?.popViewController(animated: true)
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation{
            return nil
        }
        var reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil{
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.black
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
        }
        else{
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedTitle != ""{
            
            var newLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            CLGeocoder().reverseGeocodeLocation(newLocation) { placesmarks, error in
                //closure
                if let placemark = placesmarks{
                    if placemark.count > 0 {
                        let newPlacesmark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacesmark)
                        item.name = self.annotationTitle
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
                
                
               
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //kendin konumuna gerekli yakalstirmayi yapma
        if selectedTitle == ""{
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.latitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        }
            
    }
    
    

}

