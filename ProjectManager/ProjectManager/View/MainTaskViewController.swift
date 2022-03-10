//
//  ProjectManager - MainTaskViewController.swift
//  Created by yagom. 
//  Copyright © yagom. All rights reserved.
// 

import UIKit

class MainTaskViewController: UIViewController {
    let taskTableStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 10
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    let taskInWaitingTableView = TaskTableView(state: .waiting)
    let taskInProgressTableView = TaskTableView(state: .progress)
    let taskInDoneTableView = TaskTableView(state: .done)
    
    private var taskListViewModel: TaskViewModel
    
    init(taskListViewModel: TaskViewModel) {
        self.taskListViewModel = taskListViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("스토리보드 사용하지 않음")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        configureTaskListViewModel()
        setupLongPressGesture()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        taskListViewModel.didLoaded()
    }
    
    private func configureTaskListViewModel() {
        // TODO: - ViewModel 셋업
        taskListViewModel.taskDidCreated = { [weak self] in
            guard let self = self else {
                return
            }
            self.taskInWaitingTableView.reloadData()
        }
        
        taskListViewModel.taskDidDeleted = { [weak self] (index, state) in
            guard let self = self else {
                return
            }
            
            let indexPath = IndexPath(row: index, section: 0)
            
            switch state {
            case .waiting:
                self.taskInWaitingTableView.deleteRows(at: [indexPath], with: .fade)
            case .progress:
                self.taskInProgressTableView.deleteRows(at: [indexPath], with: .fade)
            case .done:
                self.taskInDoneTableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
        
        taskListViewModel.taskDidChanged = { [weak self] (index, state) in
            guard let self = self else {
                return
            }
            
            let indexPath = IndexPath(row: index, section: 0)
            
            switch state {
            case .waiting:
                self.taskInWaitingTableView.reloadRows(at: [indexPath], with: .fade)
            case .progress:
                self.taskInProgressTableView.reloadRows(at: [indexPath], with: .fade)
            case .done:
                self.taskInDoneTableView.reloadRows(at: [indexPath], with: .fade)
            }
        }
        
        taskListViewModel.taskDidMoved = { [weak self] (index, oldState, newState) in
            guard let self = self else {
                return
            }
            
            let indexPath = IndexPath(row: index, section: 0)
            
            switch oldState {
            case .waiting:
                self.taskInWaitingTableView.deleteRows(at: [indexPath], with: .fade)
            case .progress:
                self.taskInProgressTableView.deleteRows(at: [indexPath], with: .fade)
            case .done:
                self.taskInDoneTableView.deleteRows(at: [indexPath], with: .fade)
            }
            
            switch newState {
            case .waiting:
                self.taskInWaitingTableView.reloadData()
            case .progress:
                self.taskInProgressTableView.reloadData()
            case .done:
                self.taskInDoneTableView.reloadData()
            }
        }
        
        taskListViewModel.didSelectTask = { [weak self] (index, selectedTask) in
            guard let self = self else {
                return
            }
            
            let taskManageViewController = TaskManageViewController(manageType: .detail, taskListViewModel: self.taskListViewModel, task: selectedTask, selectedIndex: index)
            let taskManageNavigationViewController = UINavigationController(rootViewController: taskManageViewController)
            taskManageNavigationViewController.modalPresentationStyle = .formSheet
    
            self.present(taskManageNavigationViewController, animated: true, completion: nil)
        }
    }
    
    private func configureUI() {
        configureNavigationController()
        configureTableView()
        configureLayout()
    }
    
    private func configureTableView() {
        [taskInWaitingTableView, taskInProgressTableView, taskInDoneTableView].forEach {
            $0.dataSource = self
            $0.delegate = self
        }
    }
    
    private func configureLayout() {
        [taskInWaitingTableView, taskInProgressTableView, taskInDoneTableView].forEach {
            taskTableStackView.addArrangedSubview($0)
        }
        
        view.addSubview(taskTableStackView)
        
        NSLayoutConstraint.activate([
            taskTableStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            taskTableStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            taskTableStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            taskTableStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func configureNavigationController() {
        navigationItem.title = "Project Manager"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTask))
    }
    
    private func createAlert(with newStates: [TaskState], completion: @escaping (TaskState) -> Void) -> UIAlertController {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        newStates.forEach { state in
            let moveAction = UIAlertAction(title: state.relocation, style: .default) { _ in
                completion(state)
            }
            alert.addAction(moveAction)
        }
        
        return alert
    }
    
    private func setupLongPressGesture() {
        let longPressOnWaiting = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressOnWaiting(_:)))
        let longPressOnProgress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressOnProgress(_:)))
        let longPressOnDone = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressOnDone(_:)))

        taskInWaitingTableView.addGestureRecognizer(longPressOnWaiting)
        taskInProgressTableView.addGestureRecognizer(longPressOnProgress)
        taskInDoneTableView.addGestureRecognizer(longPressOnDone)
    }
    
    private func longPressToMove(gesture: UILongPressGestureRecognizer, tableView: TaskTableView, from oldState: TaskState, to newStates: [TaskState]) {
        let touchPoint = gesture.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: touchPoint) else {
            return
        }
        
        if gesture.state == .began {
            let alert = createAlert(with: newStates) { state in
                self.taskListViewModel.move(at: indexPath.row, from: oldState, to: state)
            }

            alert.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
            self.present(alert, animated: true)
        }
    }
    
    @objc private func handleLongPressOnWaiting(_ sender: UILongPressGestureRecognizer) {
        longPressToMove(gesture: sender, tableView: taskInWaitingTableView, from: .waiting, to: [.progress, .done])
    }
    
    @objc private func handleLongPressOnProgress(_ sender: UILongPressGestureRecognizer) {
        longPressToMove(gesture: sender, tableView: taskInProgressTableView, from: .progress, to: [.waiting, .done])
    }
    
    @objc private func handleLongPressOnDone(_ sender: UILongPressGestureRecognizer) {
        longPressToMove(gesture: sender, tableView: taskInDoneTableView, from: .done, to: [.waiting, .progress])
    }
    
    @objc private func addTask() {
        let taskManageViewController = TaskManageViewController(manageType: .add, taskListViewModel: taskListViewModel)
        let taskManageNavigationViewController = UINavigationController(rootViewController: taskManageViewController)
        taskManageNavigationViewController.modalPresentationStyle = .formSheet
        
        self.present(taskManageNavigationViewController, animated: true, completion: nil)
    }
}

extension MainTaskViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let state = (tableView as? TaskTableView)?.state else {
            return .zero
        }
        
        return taskListViewModel.count(of: state)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: TaskTableViewCell.self, for: indexPath)
        guard let state = (tableView as? TaskTableView)?.state,
              let task = taskListViewModel.task(at: indexPath.row, from: state) else {
            return TaskTableViewCell()
        }
        
        cell.configureCell(title: task.title, description: task.description, deadline: task.deadline, state: state)
        
        return cell
    }
}

extension MainTaskViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let state = (tableView as? TaskTableView)?.state else {
            return
        }
        
        taskListViewModel.didSelectRow(at: indexPath.row, from: state)        
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, completionHandler in
            guard let state = (tableView as? TaskTableView)?.state else {
                return
            }
            
            self.taskListViewModel.deleteRow(at: indexPath.row, from: state)
            completionHandler(true)
        }
        deleteAction.backgroundColor = .red
        
        let swipeActions = UISwipeActionsConfiguration(actions: [deleteAction])
        return swipeActions
    }
}
