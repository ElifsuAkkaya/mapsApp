//
//  ViewController.swift
//  mapsApp
//
//  Created by Elifsu Akkaya on 7.01.2026.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class MapsViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
//MKMapViewDelegate = harita üzerinde pin yönetimine yardımcı olur.- CLLocationManagerDelegate= kullanıcının konumunu alır.
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var noteTextField: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager =  CLLocationManager() //kullanıcının konumunu alır.
    var chooseLatitude = Double() //yatay uzunluk
    var chooseLongitude = Double() //dikey uzunluk
    var chooseName = String()
    var chooseId : UUID?
    var annotationTitle = String()//coredatadan çekilen bilgiler
    var annotationSubtitle = String()
    var annotationLongitude : Double!
    var annotationLatitude : Double!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // desiredAccuracy = nasıl bir şekilde konum alacağımı soruyor
        locationManager.requestWhenInUseAuthorization() //konumu ne zaman alacağım hakkkında yazılan bir koddur
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:))) //gestureRecognizer = Simalator üzerinde yaptığımı herhangi bir jest yani tıklama işleminde kullanıyoruz.
        gestureRecognizer.minimumPressDuration = 3 //konum belirleme için tuşa basma süresi
        mapView.addGestureRecognizer(gestureRecognizer)
        
        if chooseName != "" {
            //core datadan veriler çekilecek
            if let uuidString = chooseId?.uuidString {
                
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
                fetchRequest.predicate = NSPredicate(format: "id == %@", uuidString)// predicate core datada filtrelem işlemi yapar. Bu demek oluyor ki isi bu olan kaydı getir.
                fetchRequest.returnsObjectsAsFaults = false
                
                do {
                    let results = try context.fetch(fetchRequest)
                
                    if results.count > 0  {
                        for result in results as! [NSManagedObject] {
                            if let name = result.value(forKey: "name") as? String {
                                annotationTitle = name
                                if let notes = result.value(forKey: "notes") as? String {
                                    annotationSubtitle = notes
                                    if let latitude = result.value(forKey: "latitude") as? Double {
                                        annotationLatitude = latitude
                                        if let longitude = result.value(forKey: "longitude") as? Double {
                                            annotationLongitude = longitude
                                            
                                            let annotation = MKPointAnnotation()
                                            annotation.title = annotationTitle
                                            annotation.subtitle = annotationSubtitle
                                            let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                            annotation.coordinate = coordinate// haritaya kayıtlı pini ekliyot.
                                            
                                            nameTextField.text = annotationTitle
                                            noteTextField.text = annotationSubtitle
                                            mapView.addAnnotation(annotation)
                                            locationManager.stopUpdatingLocation( )//lokasyon güncellemeyi başta yaptırmıştık kaydedip tableviewden seçtikten sonra bırakacak
                                            
                                            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)//ekran uzaklığı
                                            let region = MKCoordinateRegion(center: coordinate, span: span)
                                            mapView.setRegion(region, animated: true)
                                    }
                                }
                            }
                        }
                    }
                }
            }catch{
                    print("ERROR")
            }
        }
    }else {
            //yeni veri
    }
}

    @objc func chooseLocation(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: mapView)
            let touchCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView) //dokunulan noktanın haritadaki koordinatı çevirme kodu
            
            chooseLatitude = touchCoordinates.latitude
            chooseLongitude = touchCoordinates.longitude
            
            let annotation = MKPointAnnotation() //konum üzerindeki pin anlamına gelir
            annotation.coordinate = touchCoordinates
            annotation.title = nameTextField.text
            annotation.subtitle = noteTextField.text
            mapView.addAnnotation(annotation)
            
        }
        
    }
    
    @IBAction func saveButton(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newLocation = NSEntityDescription.insertNewObject(forEntityName: "Location", into: context)
        
        newLocation.setValue(nameTextField.text, forKey: "name")
        newLocation.setValue(noteTextField.text, forKey: "notes")
        newLocation.setValue(chooseLatitude, forKey: "latitude")
        newLocation.setValue(chooseLongitude, forKey: "longitude")
        newLocation.setValue(UUID(), forKey: "id")
        
        do {
            try context.save()
            print ("kayıt edildi")
        }catch {
            print("error")
        }
        NotificationCenter.default.post(name: NSNotification.Name("yeniSayfaOlusturuldu"), object: nil)
        navigationController?.popViewController(animated: true)
    }
}

extension MapsViewController {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseIdentifier = "customPin"
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) as? MKMarkerAnnotationView
        
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            annotationView?.canShowCallout = true
            annotationView?.tintColor = .red
            
            let detailButton = UIButton(type: .detailDisclosure)
            annotationView?.rightCalloutAccessoryView = detailButton
            
        } else {
            annotationView?.annotation = annotation
        }
        
        return annotationView
    }
    
    
    func mapView(_ mapView: MKMapView,
                 annotationView view: MKAnnotationView,
                 calloutAccessoryControlTapped control: UIControl) {
        
        if chooseName != "" {
            
            let requestLocation = CLLocation(latitude: annotationLatitude,
                                             longitude: annotationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarkArray, error) in
                
                if let placemarks = placemarkArray, placemarks.count > 0 {
                    
                    let newPlacemark = MKPlacemark(placemark: placemarks[0])
                    let item = MKMapItem(placemark: newPlacemark)
                    item.name = self.annotationTitle
                    
                    let launchOptions = [
                        MKLaunchOptionsDirectionsModeKey:
                        MKLaunchOptionsDirectionsModeDriving
                    ]
                    
                    item.openInMaps(launchOptions: launchOptions)
                }
            }
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        
        if chooseName == "" {
            
            let location = CLLocationCoordinate2D(
                latitude: locations[0].coordinate.latitude,
                longitude: locations[0].coordinate.longitude
            )
            
            let span = MKCoordinateSpan(latitudeDelta: 0.05,
                                        longitudeDelta: 0.05)
            
            let region = MKCoordinateRegion(center: location,
                                            span: span)
            
            mapView.setRegion(region, animated: true)
        }
    }
    
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        
        if manager.authorizationStatus == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        }
    }
}
