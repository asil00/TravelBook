//
//  ViewController.swift
//  TravelBook
//
//  Created by Asilcan Çetinkaya on 16.03.2022.
//

import UIKit
import MapKit
import CoreData
import CoreLocation

class ViewController: UIViewController , MKMapViewDelegate , CLLocationManagerDelegate{
    
    @IBOutlet weak var commentText: UITextField!
    
    @IBOutlet weak var nameText: UITextField!
    
    @IBOutlet weak var mapKit: MKMapView!
    
    var locationManager = CLLocationManager()
        var chosenLatitude = Double()
        var chosenLongitude = Double()
        
        var selectedTitle = ""
        var selectedTitleID : UUID?
        
        var annotationTitle = ""
        var annotationSubtitle = ""
        var annotationLatitude = Double()
        var annotationLongitude = Double()
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            mapKit.delegate = self
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest  // Konumu en iyi şekilde tespitini Almak için Best Seçeneğini Kullanmalıyız
             
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
            
            
            let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
            gestureRecognizer.minimumPressDuration = 3  //3 Saniye basılı tutup bulunulan yeri pinlememize olanak sağlar
            mapKit.addGestureRecognizer(gestureRecognizer)
            
            
            if selectedTitle != "" {
                //CoreData
              
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
                let idString = selectedTitleID!.uuidString
                fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
                fetchRequest.returnsObjectsAsFaults = false
                
                do {
                    let results = try context.fetch(fetchRequest)
                    if results.count > 0 {
                        
                        for result in results as! [NSManagedObject] {
                            
                            if let title = result.value(forKey: "title") as? String {
                                annotationTitle = title
                                
                                if let subtitle = result.value(forKey: "subtitle") as? String {
                                    annotationSubtitle = subtitle
                                    
                                    if let latitude = result.value(forKey: "latitude") as? Double {
                                        annotationLatitude = latitude
                                        
                                        if let longitude = result.value(forKey: "longitude") as? Double {
                                            annotationLongitude = longitude
                                            
                                            let annotation = MKPointAnnotation()
                                            annotation.title = annotationTitle
                                            annotation.subtitle = annotationSubtitle
                                            let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                            annotation.coordinate = coordinate
                                            
                                            mapKit.addAnnotation(annotation)
                                            nameText.text = annotationTitle
                                            commentText.text = annotationSubtitle
                                            
                                            locationManager.stopUpdatingLocation()
                                            
                                            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                            let region = MKCoordinateRegion(center: coordinate, span: span)
                                            mapKit.setRegion(region, animated: true)
                                            
                                            
                                        }
                                    }
                 
                                }
                            }
                        }
                    }
                } catch {
                    print("error")
                }
                
                
            } else {
                //Add New Data
            }
            
            
        }
        
        @objc func chooseLocation(gestureRecognizer:UILongPressGestureRecognizer) {
            
            if gestureRecognizer.state == .began {
                
                let touchedPoint = gestureRecognizer.location(in: self.mapKit)
                let touchedCoordinates = self.mapKit.convert(touchedPoint, toCoordinateFrom: self.mapKit)
                
                chosenLatitude = touchedCoordinates.latitude
                chosenLongitude = touchedCoordinates.longitude
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = touchedCoordinates
                annotation.title = nameText.text
                annotation.subtitle = commentText.text
                self.mapKit.addAnnotation(annotation)
                
                
            }
            
        }
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            if selectedTitle == "" {
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05) //Harita yakınlaştırma derecesini gösterir
            let region = MKCoordinateRegion(center: location, span: span)
            mapKit.setRegion(region, animated: true)
            } else {
                //
            }
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            
            if annotation is MKUserLocation {
                return nil
            }
            
            let reuseId = "myAnnotation"
            var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
            
            if pinView == nil {
                pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                pinView?.canShowCallout = true
                pinView?.tintColor = UIColor.black
                
                let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
                pinView?.rightCalloutAccessoryView = button
                
            } else {
                pinView?.annotation = annotation
            }
            
            
            
            return pinView
        }
        
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            if selectedTitle != "" {
                
                let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
                
                
                CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks, error) in
                    //closure
                    
                    if let placemark = placemarks {
                        if placemark.count > 0 {
                                          
                            let newPlacemark = MKPlacemark(placemark: placemark[0])
                            let item = MKMapItem(placemark: newPlacemark)
                            item.name = self.annotationTitle
                            let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                            item.openInMaps(launchOptions: launchOptions)
                                          
                    }
                }
            }
                
                
            }
        
        
        
        
            
        }
    @IBAction func saveButton(_ sender: Any) {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context) // Places entity den geliyor birebir aynı olması gerek
        
        
        newPlace.setValue(nameText.text , forKey: "title")
        newPlace.setValue(commentText.text , forKey: "subtitle")
        newPlace.setValue(chosenLatitude, forKey: "latitude")
        newPlace.setValue(chosenLongitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id")
        
    
        do {
            try context.save()
            print("Success")
        }catch {
            print("Error")
       }
        
    }
    


}
