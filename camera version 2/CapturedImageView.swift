//
//  CapturedImageView.swift
//  camera version 2
//
//  Created by Aaron Goldgewert on 11/29/20.
//

import UIKit
class CapturedImageView : UIView{
    //MARK:- Vars
    var image: UIImage? {
        didSet{
            guard let image = image else {return}
            imageView.image = image
        }
    }
    //MARK:- View Components
    let imageView : UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    //MARK:- Init
    override init(frame: CGRect){
        super.init(frame: .zero)
        setupView()
    }
    required init?(coder: NSCoder){
        fatalError("init(coder:) had not been implemented")
    }
    //MARK:- Setup
    func setupView(){
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .white
        layer.cornerRadius = 10
        addSubview(imageView)
        NSLayoutConstraint.activate([imageView.topAnchor.constraint(equalTo: topAnchor, constant: 2), imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2), imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2), imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2)
        ])
    }
}
