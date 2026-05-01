import Foundation

enum L10n {
    static var currentLanguage: String {
        return HSBHostsLanguageManager.shared.currentLanguage
    }
    
    static func tr(_ key: String) -> String {
        let langCode = currentLanguage.lowercased()
        let isZh = langCode.contains("zh")
        
        let translations: [String: [String: String]] = [
            "app_name": ["en": "THL Hosts", "zh": "糖葫芦 Hosts"],
            "settings": ["en": "Settings", "zh": "设置"],
            "about": ["en": "About", "zh": "关于"],
            "contact_us": ["en": "Contact Us", "zh": "联系我们"],
            "privacy_policy": ["en": "Privacy Policy", "zh": "隐私政策"],
            "version": ["en": "Version", "zh": "版本"],
            "done": ["en": "Done", "zh": "完成"],
            "import": ["en": "Import", "zh": "导入"],
            "add": ["en": "Add", "zh": "添加"],
            "active": ["en": "Active", "zh": "已启用"],
            "inactive": ["en": "Inactive", "zh": "未启用"],
            "system_active": ["en": "System Active", "zh": "系统已启用"],
            "system_inactive": ["en": "System Inactive", "zh": "系统未启用"],
            "hosts_content": ["en": "Hosts Content", "zh": "Hosts 内容"],
            "scan_to_upload": ["en": "Scan to Upload", "zh": "扫码上传"],
            "no_configs": ["en": "No Configurations", "zh": "暂无配置"],
            "upload_guide": ["en": "Upload files via QR code", "zh": "通过二维码上传文件"],
            "add_guide": ["en": "Tap + to add or import", "zh": "点击 + 添加或导入"],
            "master_switch": ["en": "Master Switch", "zh": "总开关"],
            "enable_hosts": ["en": "Enable Hosts Service", "zh": "开启 Hosts 服务"],
            "configurations": ["en": "Configurations", "zh": "配置列表"],
            "status": ["en": "Status", "zh": "状态"],
            "contact_desc": ["en": "Feedback & Support", "zh": "反馈与支持"],
            "email": ["en": "Email", "zh": "电子邮箱"],
            "new_hosts_file": ["en": "New Hosts File", "zh": "新建 Hosts 文件"],
            "enter_name_guide": ["en": "Enter a name for the new hosts configuration.", "zh": "请输入新配置的名称。"],
            "delete": ["en": "Delete", "zh": "删除"],
            "cancel": ["en": "Cancel", "zh": "取消"],
            "confirm": ["en": "Confirm", "zh": "确定"],
            "name": ["en": "Name", "zh": "名称"],
            "phone_upload_guide": ["en": "Use your phone to upload hosts files to this TV", "zh": "使用手机为电视上传 Hosts 文件"],
            "step_1_wifi": ["en": "Connect phone to same WiFi", "zh": "手机与电视连接同一 WiFi"],
            "step_2_scan": ["en": "Scan the QR code or visit URL", "zh": "扫描二维码或访问 URL"],
            "step_3_upload": ["en": "Select and upload .hosts file", "zh": "选择并上传 .hosts 文件"],
            "import_guide": ["en": "Import hosts from Files or create a new one", "zh": "从文件导入或新建配置"],
            "theme": ["en": "Theme", "zh": "主题"],
            "language": ["en": "Language", "zh": "语言"],
            "start_service": ["en": "START SERVICE", "zh": "开启服务"],
            "stop_service": ["en": "STOP SERVICE", "zh": "停止服务"],
            "system_log": ["en": "System Log", "zh": "系统日志"],
            "logging_desc": ["en": "View application runtime logs", "zh": "查看应用运行日志"],
            "follow_system": ["en": "Follow System", "zh": "跟随系统"],
            "change_config": ["en": "Change Configuration", "zh": "切换配置"],
            "active_config": ["en": "Active", "zh": "当前配置"],
            "about_content": ["en": "THL Hosts is a powerful tool for managing and redirecting network requests via hosts files. It works locally on your device to ensure privacy and speed.", "zh": "糖葫芦 Hosts 是一款强大的 Hosts 文件管理与请求转发工具。它完全在本地运行，确保您的隐私安全与访问速度。"],
            "privacy_desc": ["en": "THL Hosts is a fully offline application. We do not collect, store, or transmit any of your personal data or browsing history. All Hosts resolution happens entirely on your device.", "zh": "糖葫芦 Hosts 是一款纯离线应用。我们不会收集、存储或向外部服务器传输您的任何个人数据或浏览历史。所有 Hosts 解析均完全在您的设备本地完成。"],
            "telegram": ["en": "Telegram", "zh": "Telegram"],
            "github": ["en": "GitHub", "zh": "GitHub"],
            "press_to_change": ["en": "Press to change configuration", "zh": "按 OK 键切换配置"],
            "vpn_usage_title": ["en": "How it works", "zh": "工作原理"],
            "vpn_usage_desc": ["en": "This app uses a local VPN configuration to intercept and redirect network requests based on your hosts rules. NO data leaves your device.", "zh": "本应用使用本地 VPN 配置来拦截并根据您的 Hosts 规则转发网络请求。所有处理均在本地完成，无数据外传。"],
            "clear": ["en": "Clear", "zh": "清除"],
            "click_plus_to_add": ["en": "Tap + at the top to add a configuration", "zh": "点击顶部的 + 号添加配置"]
        ]
        
        let lang = isZh ? "zh" : "en"
        return translations[key]?[lang] ?? key
    }
}

extension String {
    var localized: String {
        return L10n.tr(self)
    }
}
