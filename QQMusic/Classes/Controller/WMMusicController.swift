//
//  ViewController.swift
//  QQMusic
//
//  Created by 王蒙 on 15/8/27.
//  Copyright © 2015年 王蒙. All rights reserved.
//

import UIKit
import AVFoundation

//MARK: 基本属性定义及初始化方法加载
class WMMusicController: UIViewController {
    /**Xcode7的注释，使用‘/// ’mark down注释语法*/
    
    /// 进度条
    @IBOutlet weak var sliderTime: UISlider!
    /// 中间的View
    @IBOutlet weak var iconView: UIView!
    /// 最大时间label
    @IBOutlet weak var maxTime: UILabel!
    /// 最小时间的label
    @IBOutlet weak var minTime: UILabel!
    /// 歌词展示的label
    @IBOutlet weak var lrcLabel: WMLrcLabel!
    /// 演唱者的名字
    @IBOutlet weak var singer: UILabel!
    /// 歌名
    @IBOutlet weak var songName: UILabel!
    /// 头像
    @IBOutlet weak var iconImageView: UIImageView!
    /// 是否选中了按钮--》是否播放
    @IBOutlet weak var playerBtn: UIButton!
    /// 背景图
    @IBOutlet weak var backGroudView: UIImageView!
    /// 当前播放歌曲
    private var currentSong = AVAudioPlayer()
    /// slider的定时器
    private var progressTimer:Timer?
    /// 歌词的定时器
    private var lrcTimer:CADisplayLink?
    /// scrollView ->歌词的展示view
    @IBOutlet weak var lrcView: WMLrcView!
    
    //MARK: 初始化设置
    override func viewDidLoad() {
        super.viewDidLoad()
        //播放歌曲
        setingPlaySong()
        lrcView.lrcLabel = lrcLabel
    }
    
}
//MARK:滑块的播放操作
extension WMMusicController {
    /**添加定时器*/
    private func addSliedTimer() {
        updateMuneInfo()
        progressTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(WMMusicController.updateMuneInfo), userInfo: nil, repeats: true)
        RunLoop.main.add(progressTimer!, forMode: .commonModes)
    }
    /**移除滑块的定时器*/
    private func removeSliderTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    /**更新页面的信息*/
    @objc private func updateMuneInfo() {
        minTime.text = currentSong.currentTime.lrcTimeString
        sliderTime.value = Float(currentSong.currentTime / currentSong.duration)
    }
    //MARK:设置滑块的状态
    @IBAction func startSlide() {
        removeSliderTimer()
    }
    @IBAction func sliderValueChange() {
        // 设置当前播放的时间Label
        minTime.text = (currentSong.duration * Double(sliderTime.value)).lrcTimeString
    }
    
    @IBAction func endSlide() {
        // 设置歌曲的播放时间
        currentSong.currentTime = currentSong.duration * Double(sliderTime.value)
        // 添加定时器
        addSliedTimer()
    }
    //MARK:滑块的点击事件
    @objc private func sliderClick(tap:UITapGestureRecognizer) {
        //获取点击的位置
        let point = tap.location(in: sliderTime)
    
        //获取点击的在slider长度中占据的比例
        let ratio = point.x / sliderTime.bounds.size.width
        //改变歌曲播放的时间
        currentSong.currentTime = Double(ratio) * currentSong.duration
        //更新进度信息
        updateMuneInfo()
    }
    //MARK:歌词的定时器设置
    //添加歌词的定时器
    private func addLrcTimer() {
        lrcTimer = CADisplayLink(target: self, selector: #selector(WMMusicController.updateLrcTimer))
        lrcTimer?.add(to: .main, forMode: .commonModes)
    }
    //删除歌词的定时器
    private func removeLrcTimer() {
        lrcTimer?.invalidate()
        lrcTimer = nil
    }
    //更新歌词的时间
    @objc private func updateLrcTimer() {
        lrcView.currentTime = currentSong.currentTime
    }
    
}
//MARK: 歌曲播放
extension WMMusicController {
    //MARK: 上一首歌曲
    @IBAction func preSong() {
        
        let previousMusic = WMMusicTool.shared.previousMusic()
        //播放
        playingMusicWithMusic(music: previousMusic)
    }
    //MARK: 播放歌曲
    @IBAction func playSong() {
        playerBtn.isSelected = !playerBtn.isSelected
        if currentSong.isPlaying {
            currentSong.pause()
            //删除滑块的定时器
            removeSliderTimer()
            //移除歌词的定时器
            removeLrcTimer()
            //暂停头像的动画
            iconImageView.layer.pauseAnimate()
        }else {
            currentSong.play()
            //添加上滑块的定时器
            addSliedTimer()
            //歌词的定时器
            removeLrcTimer()
            //恢复动画
            iconImageView.layer.resumeAnimate()
        }
    }
    //MARK: 下一首歌曲
    @IBAction func nextSong() {
        let nextSong = WMMusicTool.shared.nextMusic()
        //播放
        playingMusicWithMusic(music: nextSong)
    }
    //播放歌曲，根据传来的歌曲名字
    private func playingMusicWithMusic(music: WMMusic) {
        
        //停掉之前的
        let playerMusic = WMMusicTool.shared.playerMusic()
        WMAudioTool.stopMusic(with: playerMusic.filename!)
        lrcLabel.text = ""
        lrcView.currentTime = 0
        //播放现在的
        WMAudioTool.playMusic(with: music.filename!)
        WMMusicTool.shared.setPlayingMusic(playingMusic: music)
        setingPlaySong()
        
    }
    //MARK: 设置播放的加载项
    private func setingPlaySong() {
        
        //取出当前的播放歌曲
        let currentMusic = WMMusicTool.shared.playerMusic()
        
        //设置当前的界面信息
        backGroudView.image = UIImage(named: currentMusic.icon!)
        iconImageView.image = UIImage(named: currentMusic.icon!)
        songName.text = currentMusic.name
        singer.text = currentMusic.singer
        
        //设置歌曲播放
        let currentAudio = WMAudioTool.playMusic(with: currentMusic.filename!)
        currentAudio.delegate = self
        //设置时间
        minTime.text = currentAudio.currentTime.lrcTimeString
        maxTime.text = currentAudio.duration.lrcTimeString
        currentSong = currentAudio
        //播放按钮状态的改变
        playerBtn.isSelected = currentSong.isPlaying
        sliderTime.value = 0
        //设置歌词内容
        lrcView.lrcName = currentMusic.lrcname
        lrcView.duration = currentSong.duration
        lrcLabel.text = ""
        //移除以前的定时器
        removeSliderTimer()
        //添加定时器
        addSliedTimer()
        removeLrcTimer()
        addLrcTimer()
        startIconViewAnimate()
    }
}
//MARK: 播放器的代理以及ScrollView的代理
extension WMMusicController: AVAudioPlayerDelegate,UIScrollViewDelegate{
    //自动播放下一曲
    @objc internal func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            nextSong()
        }
    }
    //随着ScrollView的偏移，头像view隐藏
    @objc internal func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //获取到滑动的偏移
        let point = scrollView.contentOffset
        //计算偏移的比例
        let ratio = 1 - point.x / scrollView.bounds.size.width
        // 设置存放歌词和头像的view的透明度
        iconView.alpha = ratio
    }
    //监听远程事件
    override func remoteControlReceived(with event: UIEvent?) {
        switch(event!.subtype) {
        case .remoteControlPlay:
            playSong()
        case .remoteControlPause:
            playSong()
        case .remoteControlNextTrack:
            nextSong()
        case .remoteControlPreviousTrack:
            preSong()
        default:
            break
        }
    }
}
// MARK: 动画及基本设置
extension WMMusicController {
    
    //MARK: 内部的子空间的设置
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        iconImageView.layer.cornerRadius = iconImageView.bounds.width * 0.5
        iconImageView.layer.masksToBounds = true
        iconImageView.layer.borderWidth = 8
        iconImageView.layer.borderColor = UIColor(red: 36/255.0, green: 36/255.0, blue: 36/255.0, alpha: 1.0).cgColor
        
        sliderTime.setThumbImage(UIImage(named: "player_slider_playback_thumb"), for: .normal)
        lrcView.contentSize = CGSize(width: view.bounds.width * 2, height: 0)
        
    }
    //MARK: 设置状态栏的透明
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    //MARK:设置动画
    private func startIconViewAnimate() {
        let rotateAnim = CABasicAnimation(keyPath: "transform.rotation.z")
        rotateAnim.fromValue = 0
        rotateAnim.toValue = Double.pi * 2
        rotateAnim.repeatCount = Float(NSIntegerMax)
        rotateAnim.duration = 15
        
        iconImageView.layer.add(rotateAnim, forKey: nil)
        
        let tapSlider = UITapGestureRecognizer()
        tapSlider.addTarget(self, action: #selector(WMMusicController.sliderClick(tap:)))
        sliderTime.addGestureRecognizer(tapSlider)
    }
}
