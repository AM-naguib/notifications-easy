import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("Connection") {
                    TextField("API Base URL", text: $viewModel.baseURLString)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: viewModel.baseURLString) { _, _ in
                            viewModel.persistSettings()
                        }

                    SecureField("App Token (optional)", text: $viewModel.appToken)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: viewModel.appToken) { _, _ in
                            viewModel.persistSettings()
                        }
                }

                Section("Notification Settings") {
                    Stepper(value: $viewModel.notificationCount, in: 1 ... 50) {
                        HStack {
                            Text("Notification Count")
                            Spacer()
                            Text("\(viewModel.notificationCount)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onChange(of: viewModel.notificationCount) { _, _ in
                        viewModel.persistSettings()
                    }

                    Stepper(value: $viewModel.intervalSeconds, in: 1 ... 3600) {
                        HStack {
                            Text("Interval Seconds")
                            Spacer()
                            Text("\(viewModel.intervalSeconds)s")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onChange(of: viewModel.intervalSeconds) { _, _ in
                        viewModel.persistSettings()
                    }
                }

                Section("Status") {
                    LabeledContent("Notifications", value: viewModel.notificationStatusText)

                    if viewModel.isPermissionButtonVisible {
                        Button("Request Permission") {
                            Task {
                                await viewModel.requestNotificationPermission()
                            }
                        }
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }

                    Text(viewModel.lastSyncMessage)
                        .foregroundStyle(.secondary)
                }

                Section("Actions") {
                    Button {
                        Task {
                            await viewModel.fetchAndSchedule()
                        }
                    } label: {
                        HStack {
                            if viewModel.isSyncing {
                                ProgressView()
                            }
                            Text(viewModel.isSyncing ? "Scheduling..." : "Fetch & Schedule")
                        }
                    }
                    .disabled(viewModel.isSyncing)
                }

                if !viewModel.lastOrders.isEmpty {
                    Section("Last Batch Preview") {
                        ForEach(viewModel.lastOrders) { order in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(order.notificationTitle)
                                    .font(.headline)
                                Text(order.notificationBody)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("EasyOrders")
        }
        .task {
            await viewModel.bootstrap()
        }
    }
}

