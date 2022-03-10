//
//  TaskTableView.swift
//  ProjectManager
//
//  Created by 이차민 on 2022/03/09.
//

import UIKit

class TaskTableView: UITableView {
    var state: TaskState
    
    init(state: TaskState) {
        self.state = state
        super.init(frame: .zero, style: .grouped)
        backgroundColor = .systemGray5
        self.register(cellWithClass: TaskTableViewCell.self)
        self.register(headerFooterWithClass: TaskTableHeaderView.self)
    }
    
    required init?(coder: NSCoder) {
        state = .waiting
        super.init(coder: coder)
    }
}
