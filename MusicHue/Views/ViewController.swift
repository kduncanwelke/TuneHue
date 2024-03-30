//
//  ViewController.swift
//  MusicHue
//
//  Created by Kate Duncan-Welke on 8/20/19.
//  Copyright © 2019 Kate Duncan-Welke. All rights reserved.
//

import UIKit
import AnimatedGradientView
import MediaPlayer
import CoreData
import Network

class ViewController: UIViewController {
	
	// MARK: IBOutlets
	
	@IBOutlet weak var background: UIView!
    @IBOutlet weak var subBackground: UIView!
    
    @IBOutlet weak var tabBackground: UIView!
    
    @IBOutlet weak var backButton: UIImageView!
    @IBOutlet weak var forwardButton: UIImageView!
    @IBOutlet weak var playPauseButton: UIImageView!
    
    @IBOutlet weak var currentlyPlaying: UILabel!
	@IBOutlet weak var artist: UILabel!
	@IBOutlet weak var albumArt: UIImageView!
	@IBOutlet weak var timeLabel: UILabel!
	@IBOutlet weak var progress: UIProgressView!
	@IBOutlet weak var repeatButton: UIButton!
	@IBOutlet weak var shuffleButton: UIButton!
	
    
    // MARK: Variables
	
	let mediaPlayer = MPMusicPlayerController.systemMusicPlayer
	let monitor = NWPathMonitor()
	var cloudItem = false
	var textColor = TextColor.white

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
        
        if traitCollection.userInterfaceStyle == .light {
            textColor = TextColor.black
        } else {
            textColor = TextColor.white
        }
		
		mediaPlayer.beginGeneratingPlaybackNotifications()
		
		NotificationCenter.default.addObserver(self, selector: #selector(stateChanged), name: .MPMusicPlayerControllerPlaybackStateDidChange, object: mediaPlayer)
		
		NotificationCenter.default.addObserver(self, selector: #selector(newSong), name: NSNotification.Name(rawValue: "newSong"), object: nil)
		
		NotificationCenter.default.addObserver(self, selector: #selector(songDeleted), name: NSNotification.Name(rawValue: "songDeleted"), object: nil)
        
        configureColors()
		
		subBackground.layer.cornerRadius = 10
		checkForNowPlaying()
		
		mediaPlayer.repeatMode = .none
		mediaPlayer.shuffleMode = .off
		
		loadPurchasedGradients()
		
		NetworkMonitor.monitor.pathUpdateHandler = { [weak self] path in
			if path.status == .satisfied {
				print("connection successful")
				NetworkMonitor.connection = true
				NotificationCenter.default.post(name: NSNotification.Name(rawValue: "networkRestored"), object: nil)
			} else {
				print("no connection")
				NetworkMonitor.connection = false
				if let isAcloudItem = self?.mediaPlayer.nowPlayingItem?.isCloudItem {
					if isAcloudItem {
						self?.cloudItem = true
					
						DispatchQueue.main.async {
							print("cloud item no connection")
							self?.checkStatus()
						}
					} else {
						self?.cloudItem = false
					}
				}
			}
		}
		
		let queue = DispatchQueue(label: "Monitor")
		NetworkMonitor.monitor.start(queue: queue)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		let animatedGradient = AnimatedGradientView(frame: view.bounds)
		animatedGradient.animationValues = GradientManager.currentGradient
        animatedGradient.tag = 100
		background.addSubview(animatedGradient)
		
		checkStatus()
		
		print("will appear")
	}
	
	override func viewWillLayoutSubviews() {
		let animatedGradient = AnimatedGradientView(frame: self.view.bounds)
		animatedGradient.animationValues = GradientManager.currentGradient
        
        if let viewWithTag = self.view.viewWithTag(100) {
            viewWithTag.removeFromSuperview()
            self.background.addSubview(animatedGradient)
        }
	}
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.userInterfaceStyle == .light {
            textColor = TextColor.black
        } else {
            textColor = TextColor.white
        }
        
        configureColors()
    }
	
	override func becomeFirstResponder() -> Bool {
		return true
	}
	
	// detect shake gesture for shuffle toggling
	override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
		if motion == .motionShake {
			print("Shake Gesture Detected")
			
			if mediaPlayer.repeatMode != .one && mediaPlayer.shuffleMode == .off {
				mediaPlayer.shuffleMode = .songs
                shuffleButton.setImage(UIImage(named: "shuffle_on_FILL0_wght400_GRAD0_opsz24"), for: .normal)

			} else if mediaPlayer.shuffleMode == .songs {
				mediaPlayer.shuffleMode = .off
                shuffleButton.setImage(UIImage(named: "shuffle_FILL0_wght400_GRAD0_opsz24"), for: .normal)
			}
		}
	}
	
	// handle gradient display when orientation is changed
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		DispatchQueue.main.async {
			let animatedGradient = AnimatedGradientView(frame: self.view.bounds)
			animatedGradient.animationValues = GradientManager.currentGradient
			self.background.addSubview(animatedGradient)
		}
	}
	
	// MARK: Custom functions

	func setUI() {
		currentlyPlaying.text = mediaPlayer.nowPlayingItem?.title
		artist.text = mediaPlayer.nowPlayingItem?.albumArtist ?? "-"
		
		if let albumVisual = mediaPlayer.nowPlayingItem?.artwork?.image(at: albumArt.bounds.size) {
			albumArt.image = albumVisual
		} else {
			albumArt.image = UIImage(named: "noimage")
		}
		
		updateTimeLabel()
		updateProgress()
	}
	
	func updateTimeLabel() {
		timeLabel.text = {
			var seconds = Int(mediaPlayer.currentPlaybackTime)
			let ms = (mediaPlayer.currentPlaybackTime.truncatingRemainder(dividingBy: 1)) * 1000
			if ms > 0.5 {
				seconds += 1
			}
			
			if seconds < 60 {
				if seconds < 10 {
					return "0:0\(seconds)"
				} else {
					return "0:\(seconds)"
				}
			} else if seconds >= 3600 {
				let hour = Int(seconds / 3600)
				let minute = Int((seconds - (hour * 3600)) / 60)
				let second = seconds % 60
				
				if minute < 10 {
					if second < 10 {
						return "\(hour):0\(minute):0\(second)"
					} else {
						return "\(hour):0\(minute):\(second)"
					}
				}
				
				if second < 10 {
					return "\(hour):\(minute):0\(second)"
				} else {
					return "\(hour):\(minute):\(second)"
				}
			} else {
				let minute = seconds / 60
				let second = seconds % 60
				if second < 10 {
					return "\(minute):0\(second)"
				} else {
					return "\(minute):\(second)"
				}
			}
		}()
	}
	
	func updateProgress() {
		if mediaPlayer.currentPlaybackTime > 0 {
			if let current = mediaPlayer.nowPlayingItem {
				let prog = mediaPlayer.currentPlaybackTime / current.playbackDuration
				let float = Float(prog)
				progress.setProgress(float, animated: false)
			} else {
				progress.setProgress(0.0, animated: false)
			}
		}
	}
	
	func startTimer(doesRepeat: Bool) {
		if let item = mediaPlayer.nowPlayingItem {
			TimerManager.beginTimer(with: mediaPlayer.currentPlaybackTime, maxTime: item.playbackDuration, label: timeLabel, bar: progress, isRepeating: doesRepeat)
		}
	}
	
	func checkForNowPlaying() {
		if mediaPlayer.nowPlayingItem == nil {
			MusicManager.songs.removeAll()
			save()
			print("now playing nil")
		} else {
			loadSongs()
			print("loaded")
			checkStatus()
		}
	}
	
	func checkStatus() {
		if mediaPlayer.nowPlayingItem == nil {
			currentlyPlaying.text = "No selection"
			artist.text = "-"
			albumArt.image = UIImage(named: "noimage")
			
			MusicManager.songs.removeAll()
			print("check status nil")
		} else {
			if !MusicManager.songs.isEmpty {
				print("check status not nil")
				
				setUI()
				
				if cloudItem && NetworkMonitor.connection == false {
					print("no connection for item")
					mediaPlayer.pause()
					stateChanged()
					showAlert(title: "No network connection", message: "This song is streaming from the cloud - you may experience problems with playback until a data connection is restored.")
					return
				} else {
					// nothing
				}
				
				if mediaPlayer.playbackState == .playing {
                    print("playing")
                    if TimerManager.stopped {
                        startTimer(doesRepeat: repeatButton.isEnabled)
                    }
					switch textColor {
					case .white:
                        playPauseButton.image = UIImage(named: "pausedark")
					case .black:
                        playPauseButton.image = UIImage(named: "pauselight")
					}
					
				} else if mediaPlayer.playbackState == .paused || mediaPlayer.playbackState == .stopped {
					switch textColor {
					case .white:
                        playPauseButton.image = UIImage(named: "playdark")
					case .black:
                        playPauseButton.image = UIImage(named: "playlight")
					}
				}
			}
		}
	}
	
	@objc func songDeleted() {
		var collection = MPMediaItemCollection(items: MusicManager.songs)
	
		mediaPlayer.setQueue(with: collection)
		save()
        
        if let playing = mediaPlayer.nowPlayingItem {
            if !(MusicManager.songs.contains(playing)) {
                // playing item was deleted
                TimerManager.stopTimer()
            }
        }
        
        if MusicManager.songs.isEmpty {
            mediaPlayer.stop()
            mediaPlayer.nowPlayingItem = nil
            currentlyPlaying.text = "No selection"
            artist.text = "-"
            albumArt.image = UIImage(named: "noimage")
            TimerManager.stopTimer()
        } else {
            mediaPlayer.prepareToPlay()
        }
		
		checkStatus()
	}
	
	@objc func stateChanged() {
		if mediaPlayer.playbackState == .playing {
			switch textColor {
				case .white:
                    playPauseButton.image = UIImage(named: "pausedark")
				case .black:
                    playPauseButton.image = UIImage(named: "pauselight")
			}
			
			TimerManager.stopTimer()
			
			if mediaPlayer.repeatMode == .one {
				startTimer(doesRepeat: true)
			} else {
				startTimer(doesRepeat: false)
			}
        } else if mediaPlayer.playbackState == .paused || mediaPlayer.playbackState == .stopped {
            switch textColor {
            case .white:
                playPauseButton.image = UIImage(named: "playdark")
            case .black:
                playPauseButton.image = UIImage(named: "playlight")
                
                TimerManager.stopTimer()
            }
        }
	}
	
	@objc func newSong() {
		mediaPlayer.stop()
		mediaPlayer.nowPlayingItem = MusicManager.songs[MusicManager.selectedSong]
		mediaPlayer.play()
	}
	
	func save() {
		var managedContext = CoreDataManager.shared.managedObjectContext
		
		if let existing = MusicManager.playlist {
			var idList: [String] = []
			
			for song in MusicManager.songs {
				idList.append("\(song.persistentID)")
				print(song.title)
			}
			
			print(MusicManager.songs)
			print("old save")
			
			existing.songs = idList
			
			do {
				try managedContext.save()
				print("saved playlist")
			} catch {
				// this should never be displayed but is here to cover the possibility
				showAlert(title: "Save failed", message: "Notice: Data has not successfully been saved.")
				print("fail")
			}
		} else {
			let savedPlaylist = Playlist(context: managedContext)
			
			var idList: [String] = []
			
			for song in MusicManager.songs {
				idList.append("\(song.persistentID)")
				print(song.title)
			}
			
			print("new save")
		
			savedPlaylist.songs = idList
			MusicManager.playlist = savedPlaylist
			
			do {
				try managedContext.save()
				print("saved playlist")
				//NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reload"), object: nil)
			} catch {
				// this should never be displayed but is here to cover the possibility
				showAlert(title: "Save failed", message: "Notice: Data has not successfully been saved.")
				print("fail")
			}
		}
		
	}
	
	func loadSongs() {
		var managedContext = CoreDataManager.shared.managedObjectContext
		var fetchRequest = NSFetchRequest<Playlist>(entityName: "Playlist")
		
		do {
			var list = try managedContext.fetch(fetchRequest)
			
			MusicManager.playlist = list.first
			
			if let playlist = MusicManager.playlist?.songs {
				var retrievedSongs: [MPMediaItem] = []
				
				for song in playlist {
					let predicate = MPMediaPropertyPredicate(value: song, forProperty: MPMediaItemPropertyPersistentID)
					let songQuery = MPMediaQuery.init(filterPredicates: [predicate])
					
					if let items = songQuery.items, items.count > 0 {
						retrievedSongs.append(items[0])
                        print("added song")
					}
				}
				
				MusicManager.songs = retrievedSongs
			}
			
			print("music loaded")
		} catch let error as NSError {
			showAlert(title: "Could not retrieve data", message: "\(error.userInfo)")
			print("fail")
		}
	}
	
	func loadPurchasedGradients() {
		var managedContext = CoreDataManager.shared.managedObjectContext
		var fetchRequest = NSFetchRequest<SavedGradient>(entityName: "SavedGradient")
		
		do {
			var gradients = try managedContext.fetch(fetchRequest)
			
			for gradient in gradients {
				print(gradient)
				GradientManager.addToPurchased(loaded: gradient)
			}
			
			print("gradients loaded")
		} catch let error as NSError {
			showAlert(title: "Could not retrieve data", message: "\(error.userInfo)")
			print("fail")
		}
	}
    
    func configureColors() {
        switch textColor {
        case .white:
            subBackground.backgroundColor = UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 0.6)
            tabBackground.backgroundColor = UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 0.6)
            forwardButton.image = UIImage(named: "forwarddark")
            backButton.image = UIImage(named: "backwarddark")
            
            switch mediaPlayer.playbackState {
            case .playing:
                playPauseButton.image = UIImage(named: "pausedark")
            default:
                playPauseButton.image = UIImage(named: "playdark")
            }
        case .black:
            subBackground.backgroundColor = UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 0.6)
            tabBackground.backgroundColor = UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 0.6)
            forwardButton.image = UIImage(named: "forwardlight")
            backButton.image = UIImage(named: "backwardlight")
            
            switch mediaPlayer.playbackState {
            case .playing:
                playPauseButton.image = UIImage(named: "pauselight")
            default:
                playPauseButton.image = UIImage(named: "playlight")
            }
        }
    }
	
	// MARK: IBActions
    
    @IBAction func tapMusic(_ sender: UITapGestureRecognizer) {
        let status = MPMediaLibrary.authorizationStatus()
        switch status {
        case .authorized:
            DispatchQueue.main.async {
                let myMediaPickerVC = MPMediaPickerController(mediaTypes: MPMediaType.music)
                myMediaPickerVC.allowsPickingMultipleItems = true
                myMediaPickerVC.popoverPresentationController?.sourceView = nil
                myMediaPickerVC.delegate = self
                self.present(myMediaPickerVC, animated: true, completion: nil)
            }
            print("ok")
        case .denied:
            showSettingsAlert(title: "Music library inaccessible", message: "Please edit settings if you wish to allow music library access")
            return
        case .restricted:
            DispatchQueue.main.async {
                let myMediaPickerVC = MPMediaPickerController(mediaTypes: MPMediaType.music)
                myMediaPickerVC.allowsPickingMultipleItems = true
                myMediaPickerVC.popoverPresentationController?.sourceView = nil
                myMediaPickerVC.delegate = self
                self.present(myMediaPickerVC, animated: true, completion: nil)
            }
            print("restricted")
        case .notDetermined:
            MPMediaLibrary.requestAuthorization() { [weak self] status in
                if status == .authorized {
                    DispatchQueue.main.async {
                        let myMediaPickerVC = MPMediaPickerController(mediaTypes: MPMediaType.music)
                        myMediaPickerVC.allowsPickingMultipleItems = true
                        myMediaPickerVC.popoverPresentationController?.sourceView = nil
                        myMediaPickerVC.delegate = self
                        self?.present(myMediaPickerVC, animated: true, completion: nil)
                    }
                }
            }
        @unknown default:
            print("error")
        }
    }
    
    @IBAction func tapPlaylist(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "viewSongs", sender: Any?.self)
    }
    
    @IBAction func tapColors(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "changeColor", sender: Any?.self)
    }
    
    @IBAction func tapAbout(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "showAbout", sender: Any?.self)
    }
	
    @IBAction func playPausePressed(_ sender: UITapGestureRecognizer) {
        if MusicManager.songs.isEmpty {
            return
        }
        
        playPauseButton.animateButton()
        
        if cloudItem && NetworkMonitor.connection == false {
            return
        }
        
        if mediaPlayer.playbackState == .playing {
            mediaPlayer.pause()
            TimerManager.stopTimer()
        } else {
            mediaPlayer.play()
            startTimer(doesRepeat: repeatButton.isEnabled)
        }
    }
	
    @IBAction func forwardTap(_ sender: UITapGestureRecognizer) {
        if MusicManager.songs.isEmpty {
            return
        }
        
        forwardButton.animateButton()
        mediaPlayer.skipToNextItem()
        setUI()
        TimerManager.stopTimer()
    }
	
    @IBAction func backTap(_ sender: UITapGestureRecognizer) {
        if MusicManager.songs.isEmpty {
            return
        }
        
        backButton.animateButton()
        mediaPlayer.skipToPreviousItem()
        setUI()
        TimerManager.stopTimer()
    }
	
	@IBAction func changeRepeat(_ sender: UIButton) {
        if MusicManager.songs.isEmpty {
            return
        }
        
		switch mediaPlayer.repeatMode {
		case .none:
			mediaPlayer.repeatMode = .one
			
            repeatButton.setImage(UIImage(named: "repeat_one_on_FILL0_wght400_GRAD0_opsz24"), for: .normal)
        
			TimerManager.stopTimer()
			if mediaPlayer.playbackState == .playing {
				startTimer(doesRepeat: true)
			}
			
            shuffleButton.setImage(UIImage(named: "shuffle_FILL0_wght400_GRAD0_opsz24"), for: .normal)
			
			mediaPlayer.shuffleMode = .off
			shuffleButton.isEnabled = false
		case .one:
			mediaPlayer.repeatMode = .all
			
            repeatButton.setImage(UIImage(named: "repeat_on_FILL0_wght400_GRAD0_opsz24"), for: .normal)
			
			shuffleButton.isEnabled = true
			
			TimerManager.stopTimer()
			if mediaPlayer.playbackState == .playing {
				startTimer(doesRepeat: false)
			}
		case .all:
			mediaPlayer.repeatMode = .none
			
            repeatButton.setImage(UIImage(named: "repeat_FILL0_wght400_GRAD0_opsz24"), for: .normal)
		default:
			break
		}
	}
	
	@IBAction func changeShuffle(_ sender: UIButton) {
        if MusicManager.songs.isEmpty {
            return
        }
        
		if mediaPlayer.shuffleMode == .off {
			mediaPlayer.shuffleMode = .songs
			
            shuffleButton.setImage(UIImage(named: "shuffle_on_FILL0_wght400_GRAD0_opsz24"), for: .normal)
		} else if mediaPlayer.shuffleMode == .songs {
			mediaPlayer.shuffleMode = .off
			
            shuffleButton.setImage(UIImage(named: "shuffle_FILL0_wght400_GRAD0_opsz24"), for: .normal)
		}
	}
}


// music picker extension
extension ViewController: MPMediaPickerControllerDelegate {
	func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
		
		if MusicManager.songs.isEmpty {
			mediaPlayer.setQueue(with: mediaItemCollection)
			mediaPlayer.play()
		} else {
			let queue = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: mediaItemCollection)
			mediaPlayer.append(queue)
		}
		
		for item in mediaItemCollection.items {
			MusicManager.songs.append(item)
			print(item.title)
			print(item.persistentID)
		}
		
		save()
		
		mediaPicker.dismiss(animated: true, completion: nil)
		
		checkStatus()
	}
	
	func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
		mediaPicker.dismiss(animated: true, completion: nil)
		checkStatus()
	}
}
