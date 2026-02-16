//
//  CategorySlider.swift
//  Universal
//
//  Created by Mark on 17/03/2018.
//  Copyright © 2018 Sherdle. All rights reserved.
//

import Foundation

class CategorySlider: UICollectionReusableView,UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet private weak var collectionView: UICollectionView!
    
    var categories = [WooProductCategory]()
    
    func loadCategories() {
        setupList()
        
        if (categories.count > 0) { return }
        
        WooProductCategory.getList(with: 10) { (success, results, error) in
            if let error = error {
                print("result: ", results ?? "");
                print("Error searching : \(error)")
                return
            }
            
            if let results = results {
        
                self.categories += results
                self.collectionView.reloadData()
                
            }
        }
    }
    
    func setupList() {
        collectionView.delegate = self
        collectionView.dataSource = self
        let flow = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        flow.scrollDirection = UICollectionView.ScrollDirection.horizontal
        flow.minimumInteritemSpacing = 0;
        flow.minimumLineSpacing = 0;
        collectionView.collectionViewLayout = flow
    }
    
    func selectedCategory() -> WooProductCategory {
        return self.categories[(self.collectionView?.indexPathsForSelectedItems![0].item)!]
    }
    
    // tell the collection view how many cells to make
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.categories.count
    }
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath)
        if let annotateCell = cell as? CategoryCell {
            annotateCell.category = self.categories[indexPath.item]
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = self.collectionView.frame.size.height
        let widthHeightRatio = CategoryCell.widthHeightRatio
        return CGSize(width: height / CGFloat(widthHeightRatio), height: height)
    }
    
}
