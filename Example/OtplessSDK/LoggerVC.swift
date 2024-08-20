//
//  LoggerVC.swift
//  OtplessSDK_Example
//
//  Created by Sparsh on 26/07/24.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import UIKit

class LoggerVC: UIViewController {
    var tableView: UITableView!
    
    var headerLabel: UILabel = {
        let label = UILabel()
        label.text = "Otpless Logs"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.textColor = .black
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        setupHeaderLabel()
        setupTableView()
    }
    
    private func setupHeaderLabel() {
        view.addSubview(headerLabel)
        
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupTableView() {
        tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(LogCell.self, forCellReuseIdentifier: LogCell.identifier)
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100
        tableView.backgroundColor = .white
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 10),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}

extension LoggerVC: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ViewController.logs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: LogCell.identifier, for: indexPath) as! LogCell
        let log = ViewController.logs[indexPath.row]
        cell.configure(with: log)
        return cell
    }
}

class LogCell: UITableViewCell {

    static let identifier = "LogCell"
    
    private let typeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textColor = .black
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textColor = .black
        return label
    }()
    
    private let copyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Copy", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var logMessage: String?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(typeLabel)
        contentView.addSubview(messageLabel)
        contentView.addSubview(copyButton)
        
        contentView.backgroundColor = .white
        
        NSLayoutConstraint.activate([
            typeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            typeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            
            messageLabel.topAnchor.constraint(equalTo: typeLabel.bottomAnchor, constant: 10),
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            messageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            
            copyButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            copyButton.leadingAnchor.constraint(equalTo: typeLabel.trailingAnchor, constant: 20)
        ])
        
        copyButton.addTarget(self, action: #selector(copyButtonTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func copyButtonTapped() {
        if let logMessage = logMessage {
            UIPasteboard.general.string = logMessage
        }
    }
    
    func configure(with log: CustomLog) {
        typeLabel.text = log.type + ", at " + log.time
        messageLabel.text = log.message
        logMessage = log.message
    }
}
