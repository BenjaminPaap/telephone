//
//  DefaultInteractorFactory.swift
//  Telephone
//
//  Copyright (c) 2008-2016 Alexey Kuznetsov
//  Copyright (c) 2016 64 Characters
//
//  Telephone is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Telephone is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import UseCases

class DefaultInteractorFactory {
    let repository: SystemAudioDeviceRepository
    let userDefaults: UserDefaults

    init(repository: SystemAudioDeviceRepository, userDefaults: UserDefaults) {
        self.repository = repository
        self.userDefaults = userDefaults
    }
}

extension DefaultInteractorFactory: InteractorFactory {
    func createUserAgentSoundIOSelectionInteractor(userAgent userAgent: UserAgent) -> ThrowingInteractor {
        return UserAgentSoundIOSelectionInteractor(
            repository: repository,
            userAgent: userAgent,
            userDefaults: userDefaults
        )
    }

    func createUserDefaultsSoundIOLoadInteractor(output output: UserDefaultsSoundIOLoadInteractorOutput) -> ThrowingInteractor {
        return UserDefaultsSoundIOLoadInteractor(
            repository: repository,
            userDefaults: userDefaults,
            output: output
        )
    }

    func createUserDefaultsSoundIOSaveInteractor(soundIO soundIO: PresentationSoundIO) -> Interactor {
        return UserDefaultsSoundIOSaveInteractor(soundIO: soundIO, userDefaults: userDefaults)
    }

    func createUserDefaultsRingtoneSoundNameSaveInteractor(name name: String) -> Interactor {
        return UserDefaultsRingtoneSoundNameSaveInteractor(name: name, userDefaults: userDefaults)
    }
}
