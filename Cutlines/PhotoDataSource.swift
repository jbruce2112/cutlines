//
//  PhotoDataSource.swift
//  Cutlines
//
//  Created by John Bruce on 1/31/17.
//  Copyright © 2017 Bruce32. All rights reserved.
//

import UIKit
import CoreData

enum UpdateResult {
	
	case success(Photo?)
	case failure(Error)
}

class PhotoDataSource: NSObject {
	
	// MARK: Properties
	var photos = [Photo]()
	
	private let entityName = "Photo"
	
	private let persistantContainer: NSPersistentContainer = {
		
		let persistantStoreURL = appGroupURL.appendingPathComponent("PhotoStore.sqlite")
		
		let container = NSPersistentContainer(name: "Cutlines")
		container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: persistantStoreURL)]
		container.loadPersistentStores { (_, error) in
			
			if let error = error {
				Log("Error setting up Core Data \(error)")
			}
		}
		return container
	}()
	
	// MARK: Functions
	func refresh(completion: @escaping (UpdateResult) -> Void) {
		
		let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
		
		let sortByDateAdded = NSSortDescriptor(key: #keyPath(Photo.dateAdded), ascending: true)
		fetchRequest.sortDescriptors = [sortByDateAdded]
		
		// Filter out those that are marked for deletion
		fetchRequest.predicate = NSPredicate(format: "\(#keyPath(Photo.markedDeleted)) == NO")
		
		let viewContext = persistantContainer.viewContext
		viewContext.perform {
			
			do {
				try self.photos = viewContext.fetch(fetchRequest)
				completion(.success(nil))
			} catch {
				completion(.failure(error))
			}
		}
	}
	
	func fetchOnlyLocal(limit: Int?) -> [Photo] {
		
		let predicate = NSPredicate(format: "\(#keyPath(Photo.ckRecord)) == nil AND \(#keyPath(Photo.markedDeleted)) == NO")
		return fetch(withPredicate: predicate, limit: limit)
	}
	
	func fetchModified(limit: Int?) -> [Photo] {
		
		let predicate = NSPredicate(format: "\(#keyPath(Photo.dirty)) == YES AND \(#keyPath(Photo.markedDeleted)) == NO")
		return fetch(withPredicate: predicate, limit: limit)
	}
	
	func fetchDeleted(limit: Int?) -> [Photo] {
		
		let predicate = NSPredicate(format: "\(#keyPath(Photo.markedDeleted)) == YES")
		return fetch(withPredicate: predicate, limit: limit)
	}
	
	func fetch(withID id: String) -> Photo? {
		
		let predicate = NSPredicate(format: "\(#keyPath(Photo.photoID)) == %@ AND \(#keyPath(Photo.markedDeleted)) == NO", id)
		return fetch(withPredicate: predicate, limit: 1).first
	}
	
	func fetch(containing searchTerm: String) -> [Photo] {
		
		let predicate = NSPredicate(format: "\(#keyPath(Photo.caption)) contains[c] %@ AND \(#keyPath(Photo.markedDeleted)) == NO", searchTerm)
		return fetch(withPredicate: predicate, limit: nil)
	}
	
	func addPhoto(_ photo: CloudPhoto, completion: @escaping (UpdateResult) -> Void) {
		
		addPhoto(id: photo.photoID!, caption: photo.caption!, dateTaken: photo.dateTaken! as Date) { result in
		
			switch result {
				
			case let .success(newPhoto):
				
				let viewContext = self.persistantContainer.viewContext
				
				// Set the remaining properties
				newPhoto!.ckRecord = photo.ckRecord
				newPhoto!.dateAdded = photo.dateAdded
				newPhoto!.lastUpdated = photo.lastUpdated
				
				do {
					
					try viewContext.save()
					completion(.success(newPhoto))
				} catch {
					
					completion(.failure(error))
					Log("Error saving context \(error)")
				}
				
			case let .failure(error):
				completion(.failure(error))
			}
		}
	}
	
	func addPhoto(id: String, caption: String, dateTaken: Date, completion: @escaping (UpdateResult) -> Void) {
		
		let viewContext = persistantContainer.viewContext
		viewContext.perform {
			
			assert(caption != captionPlaceholder)
			
			let entityDescription = NSEntityDescription.entity(forEntityName: self.entityName, in: viewContext)
			let photo = NSManagedObject(entity: entityDescription!, insertInto: viewContext) as! Photo
			photo.photoID = id
			photo.caption = caption
			photo.dateTaken = dateTaken as NSDate
			photo.dateAdded = NSDate()
			photo.lastUpdated = NSDate()
			
			viewContext.insert(photo)
			
			do {
				try viewContext.save()
				completion(.success(photo))
			} catch {
				viewContext.rollback()
				completion(.failure(error))
			}
		}
	}
	
	func delete(photoWithID id: String, completion: @escaping (UpdateResult) -> Void) {
		
		let viewContext = persistantContainer.viewContext
		viewContext.perform {
			
			guard let photo = self.fetch(withID: id) else {
				Log("Photo not deleted from CoreData because we couldn't find it")
				// Still successful even if we didn't have the photo
				completion(.success(nil))
				return
			}
			
			viewContext.delete(photo)
			
			do {
				try viewContext.save()
				completion(.success(nil))
			} catch {
				completion(.failure(error))
			}
		}
	}
	
	func delete(photos: [Photo], completion: ((UpdateResult) -> Void)?) {
		
		let viewContext = persistantContainer.viewContext
		viewContext.perform {
			
			for photo in photos {
				viewContext.delete(photo)
			}
			
			do {
				try viewContext.save()
				completion?(.success(nil))
			} catch {
				completion?(.failure(error))
			}
		}
	}
	
	func save() {
		
		let viewContext = persistantContainer.viewContext
		viewContext.perform {
			
			do {
				try viewContext.save()
			} catch {
				viewContext.rollback()
				Log("Error saving context \(error)")
			}
		}
	}
	
	private func fetch(withPredicate predicate: NSPredicate, limit: Int?) -> [Photo] {
		
		var photos = [Photo]()
		
		let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
		fetchRequest.predicate = predicate
		
		if let limit = limit {
			fetchRequest.fetchLimit = limit
		}
		
		let viewContext = persistantContainer.viewContext
		viewContext.performAndWait {
			
			do {
				try photos = viewContext.fetch(fetchRequest)
			} catch {
				Log("Error fetching photos \(error)")
			}
		}
		
		return photos
	}
}

// MARK: UICollectionViewDataSource conformance
extension PhotoDataSource: UICollectionViewDataSource {
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		
		return photos.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		
		return collectionView.dequeueReusableCell(withReuseIdentifier: "UICollectionViewCell", for: indexPath)
	}
}
