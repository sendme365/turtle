![mahua](mahua-logo.jpg)
##MaHua是什么?
一个在线编辑markdown文档的编辑器

向Mac下优秀的markdown编辑器mou致敬

##MaHua有哪些功能？

* 方便的`导入导出`功能
    *  直接把一个markdown的文本文件拖放到当前这个页面就可以了
    *  导出为一个html格式的文件，样式一点也不会丢失
* 编辑和预览`同步滚动`，所见即所得（右上角设置）
* `VIM快捷键`支持，方便vim党们快速的操作 （右上角设置）
* 强大的`自定义CSS`功能，方便定制自己的展示
* 有数量也有质量的`主题`,编辑器和预览区域
* 完美兼容`Github`的markdown语法
* 预览区域`代码高亮`


##有问题反馈
在使用中有任何问题，欢迎反馈给我，可以用以下联系方式跟我交流

* 邮件(dev.hubo#gmail.com, 把#换成@)
* weibo: [@草依山](http://weibo.com/ihubo)
* twitter: [@ihubo](http://twitter.com/ihubo)

##捐助开发者
在兴趣的驱动下,写一个`免费`的东西，有欣喜，也还有汗水，希望你喜欢我的作品，同时也能支持一下。

##感激
感谢以下的项目,排名不分先后

* [mou](http://mouapp.com/) 

##关于作者

```javascript
  var ihubo = {
    nickName  : "草依山",
    site : "http://jser.me"
  }
```

# Turtle
##Changelog (v9.1)
- Add VPN mode to start/stop both MA/FR VPN  
(require openfortivpn installed https://github.com/adrienverge/openfortivpn)
- Change VPN status check
- save and pass AD password during Push/Pull modes without multiple input  

***

##Changelog (v9)
- Added Push/Pull modes to transfer files from remote to local or local to remote.
Changes
- Change output display project name, data center and hybris version in turtle -l list mode.   
- Add backoffice Page in browser mode 
 
***

##Changelog (v8 beta final)
- Added environment selection for browser and info modes - modes can now be used without designating an environment in the command's parameters.
Changes
- Fixed a bug preventing Turtle from detecting whether "turtle -r" was run properly, sometimes resulting in having to run this twice.
- Sort introduced for normal mode when connecting to servers with numbers greater than 10. 

***

##Changelog (v8 beta 5)
- Connect mode is now default - you no longer need to specific -c or c to initiate connections.
- Dashes are no longer required before parameters. i.e. “turtle b jna s”
- Edit Turtle settings from within Turtle via “turtle -s”
- Turtle will refuse to connect to environments with incorrect env files as a form of error prevention.
- Fixed wiki mode not working for newly downloaded environments.
- Fixed hosts file generator not generating correct backoffice IPs for some environments.
- Added warning for incorrectly structured environment files.
- Label tweaks for when newWindowMode is false.
- 7 day env repository warning is suppressed when autoDailyRefresh is enabled.
- Added warning for List mode when there is a low number of environments.
- Added setting to choose the default editor for settings mode.
- Fixed and reimplemented errors for when no servers are found.

***

##Changelog (v8 beta 4)
- Added many new modes, including jumpbox, info, list, hosts, and wiki.
- Total syntax overhaul for better separation of functionality.
- Added colours for warnings and errors.
- Added warning if user is not on the right datacentre for browser URLs.
- Script settings separated into new file named CONFIG.
- Added warning if local repository is more than 7 days old.
- Heavily increased error handling, code comments and failsafes.

***

##FAQ
- How do I change the default terminal window size?
- Edit the CONFIG file in the turtle directory in order to change this.
- Why aren't all environment files included in a Turtle generated hosts file?
- Not all environments are live or have a specific purpose within hybris Cloud Services. These are therefore omitted from the generated hosts file. If an error is found with this process please report it to Tom Kendall.

***

##Future features and suggestions
Load last test results from Wiki of a specific customer and environment.
Generate a draw.io diagram based on a project's environment file.
Allow for more settings based on user feedback.
Low Priority: Check for new version of Turtle.
Low Priority: Add support for other HEC datacentres.
Low Priority: Add support for Windows.
Low Priority: Build a GUI for Turtle.

##Support
Turtle was written by Goh M,Tom Kendall and Ted T from the Sydney PSE team. Contact them for any issues or help.
