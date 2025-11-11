//
//  ExerciseHubView.swift
//  MyKenko-iOS
//
//  Created by OpenAI Assistant on 05/06/2024.
//

import SwiftUI
import MyKenkoCore

struct ExerciseHubView: View {
    @EnvironmentObject private var box: StoreBox
    @EnvironmentObject private var session: SessionManager
    @State private var section: HubSection = .routines
    @State private var showingAddRoutine = false
    @State private var showingAddExercise = false

    private enum HubSection: Int, CaseIterable, Identifiable {
        case routines
        case exercises

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .routines: return "Routines"
            case .exercises: return "Exercises"
            }
        }
    }

    private var userID: String? { session.signedInUser?.identifier }

    private var userExercises: [Exercise] {
        guard let userID else { return [] }
        return box.store.exercises.filter { $0.ownerIdentifier == userID }
    }

    private var userRoutines: [Routine] {
        guard let userID else { return [] }
        return box.store.routines.filter { $0.ownerIdentifier == userID }
    }

    private var exercisesByID: [UUID: Exercise] {
        Dictionary(uniqueKeysWithValues: userExercises.map { ($0.id, $0) })
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Picker("Section", selection: $section) {
                    ForEach(HubSection.allCases) { segment in
                        Text(segment.title).tag(segment)
                    }
                }
                .pickerStyle(.segmented)

                ScrollView {
                    VStack(spacing: 16) {
                        if section == .routines {
                            routinesSection
                        } else {
                            exercisesSection
                        }
                    }
                    .padding(.vertical)
                }
            }
            .padding(.horizontal)
            .navigationTitle("Exercise Hub")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        switch section {
                        case .routines: showingAddRoutine = true
                        case .exercises: showingAddExercise = true
                        }
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddExercise) {
            ExerciseFormView(ownerIdentifier: userID) { exercise in
                box.objectWillChange.send()
                box.store.add(exercise)
            }
        }
        .sheet(isPresented: $showingAddRoutine) {
            RoutineFormView(availableExercises: userExercises, ownerIdentifier: userID) { routine in
                box.objectWillChange.send()
                box.store.add(routine)
            }
        }
    }

    @ViewBuilder
    private var routinesSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your Routines")
                    .font(.title3.bold())

                if userRoutines.isEmpty {
                    ContentUnavailableView(
                        "No routines yet",
                        systemImage: "list.bullet.rectangle.portrait",
                        description: Text("Create a routine to group the exercises you want to complete together.")
                    )
                    .frame(maxWidth: .infinity)
                } else {
                    ForEach(userRoutines) { routine in
                        RoutineSummaryView(
                            routine: routine,
                            exercises: routine.exerciseIDs.compactMap { exercisesByID[$0] }
                        )

                        if routine.id != userRoutines.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var exercisesSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your Exercises")
                    .font(.title3.bold())

                if userExercises.isEmpty {
                    ContentUnavailableView(
                        "No exercises yet",
                        systemImage: "dumbbell",
                        description: Text("Add exercises with the plus button to build your training library.")
                    )
                    .frame(maxWidth: .infinity)
                } else {
                    ForEach(userExercises) { exercise in
                        ExerciseSummaryView(exercise: exercise)

                        if exercise.id != userExercises.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }
}

private struct ExerciseSummaryView: View {
    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(exercise.name)
                .font(.headline)
            Text("Sets: \(exercise.numberOfSets)  ·  Reps: \(exercise.repetitionsPerSet)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let instructions = exercise.instructions, !instructions.isEmpty {
                Text(instructions)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct RoutineSummaryView: View {
    let routine: Routine
    let exercises: [Exercise]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(routine.name)
                .font(.headline)

            if exercises.isEmpty {
                Text("No exercises assigned yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(exercises) { exercise in
                        Text("• \(exercise.name) – \(exercise.numberOfSets)x\(exercise.repetitionsPerSet)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ExerciseFormView: View {
    @Environment(\.dismiss) private var dismiss

    var ownerIdentifier: String?
    var onSave: (Exercise) -> Void

    @State private var name = ""
    @State private var sets = ""
    @State private var reps = ""
    @State private var instructions = ""

    private var canSave: Bool {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let setsValue = Int(sets), setsValue > 0,
              let repsValue = Int(reps), repsValue > 0 else { return false }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                    TextField("Number of Sets", text: $sets)
                        .keyboardType(.numberPad)
                    TextField("Reps per Set", text: $reps)
                        .keyboardType(.numberPad)
                }

                Section("Instructions (Optional)") {
                    TextEditor(text: $instructions)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("New Exercise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let setsValue = Int(sets),
                              let repsValue = Int(reps) else { return }
                        let trimmedInstructions = instructions.trimmingCharacters(in: .whitespacesAndNewlines)
                        let exercise = Exercise(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            numberOfSets: setsValue,
                            repetitionsPerSet: repsValue,
                            instructions: trimmedInstructions.isEmpty ? nil : trimmedInstructions,
                            ownerIdentifier: ownerIdentifier
                        )
                        onSave(exercise)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}

private struct RoutineFormView: View {
    @Environment(\.dismiss) private var dismiss

    let availableExercises: [Exercise]
    var ownerIdentifier: String?
    var onSave: (Routine) -> Void

    @State private var name = ""
    @State private var selectedExerciseIDs: Set<UUID> = []

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Routine Name", text: $name)
                }

                Section("Exercises") {
                    if availableExercises.isEmpty {
                        Text("Add exercises first so you can attach them to a routine.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(availableExercises) { exercise in
                            Toggle(isOn: binding(for: exercise)) {
                                Text(exercise.name)
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Routine")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let routine = Routine(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            exerciseIDs: Array(selectedExerciseIDs),
                            ownerIdentifier: ownerIdentifier
                        )
                        onSave(routine)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func binding(for exercise: Exercise) -> Binding<Bool> {
        Binding {
            selectedExerciseIDs.contains(exercise.id)
        } set: { isOn in
            if isOn {
                selectedExerciseIDs.insert(exercise.id)
            } else {
                selectedExerciseIDs.remove(exercise.id)
            }
        }
    }
}

#Preview {
    ExerciseHubView()
        .environmentObject(StoreBox(store: InMemoryStore(
            exercises: [
                Exercise(name: "Bench Press", numberOfSets: 3, repetitionsPerSet: 10, instructions: "Keep your back flat.", ownerIdentifier: "preview")
            ],
            routines: [
                Routine(name: "Upper Body", exerciseIDs: [], ownerIdentifier: "preview")
            ]
        )))
        .environmentObject(SessionManager())
}
