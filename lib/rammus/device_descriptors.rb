# frozen_string_literal: true

module Rammus
  DEVICE_DESCRIPTORS = {
    "Blackberry PlayBook" => {
      user_agent: "Mozilla/5.0 (PlayBook; U; RIM Tablet OS 2.1.0; en-US) AppleWebKit/536.2+ (KHTML like Gecko) Version/7.2.1.0 Safari/536.2+",
      viewport: {
        width: 600,
        height: 1024,
        device_scale_factor: 1,
        is_mobile: true,
        has_touch: true,
        is_landscape: false
      }
    },
    "Blackberry PlayBook landscape" => {
      user_agent: "Mozilla/5.0 (PlayBook; U; RIM Tablet OS 2.1.0; en-US) AppleWebKit/536.2+ (KHTML like Gecko) Version/7.2.1.0 Safari/536.2+",
      viewport: {
        width: 1024,
        height: 600,
        device_scale_factor: 1,
        is_mobile: true,
        has_touch: true,
        is_landscape: true
      }
    },
    "BlackBerry Z30" => {
      user_agent: "Mozilla/5.0 (BB10; Touch) AppleWebKit/537.10+ (KHTML, like Gecko) Version/10.0.9.2372 Mobile Safari/537.10+",
      viewport: {
        width: 360,
        height: 640,
        device_scale_factor: 2,
        is_mobile: true,
        has_touch: true,
        is_landscape: false
      }
    },
    "BlackBerry Z30 landscape" => {
      user_agent: "Mozilla/5.0 (BB10; Touch) AppleWebKit/537.10+ (KHTML, like Gecko) Version/10.0.9.2372 Mobile Safari/537.10+",
      viewport: {
        width: 640,
        height: 360,
        device_scale_factor: 2,
        is_mobile: true,
        has_touch: true,
        is_landscape: true
      }
    },
    "Galaxy Note 3" => {
      user_agent: "Mozilla/5.0 (Linux; U; Android 4.3; en-us; SM-N900T Build/JSS15J) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30",
      viewport: {
        width: 360,
        height: 640,
        device_scale_factor: 3,
        is_mobile: true,
        has_touch: true,
        is_landscape: false
      }
    },
    "Galaxy Note 3 landscape" => {
      user_agent: "Mozilla/5.0 (Linux; U; Android 4.3; en-us; SM-N900T Build/JSS15J) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30",
      viewport: {
        width: 640,
        height: 360,
        device_scale_factor: 3,
        is_mobile: true,
        has_touch: true,
        is_landscape: true
      }
    },
    "Galaxy Note II" => {
      user_agent: "Mozilla/5.0 (Linux; U; Android 4.1; en-us; GT-N7100 Build/JRO03C) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30",
      viewport: {
        width: 360,
        height: 640,
        device_scale_factor: 2,
        is_mobile: true,
        has_touch: true,
        is_landscape: false
      }
    },
    "Galaxy Note II landscape" => {
      user_agent: "Mozilla/5.0 (Linux; U; Android 4.1; en-us; GT-N7100 Build/JRO03C) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30",
      viewport: {
        width: 640,
        height: 360,
        device_scale_factor: 2,
        is_mobile: true,
        has_touch: true,
        is_landscape: true
      }
    },
    "Galaxy S III" => {
      user_agent: "Mozilla/5.0 (Linux; U; Android 4.0; en-us; GT-I9300 Build/IMM76D) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30",
      viewport: {
        width: 360,
        height: 640,
        device_scale_factor: 2,
        is_mobile: true,
        has_touch: true,
        is_landscape: false
      }
    },
    "Galaxy S III landscape" => {
      user_agent: "Mozilla/5.0 (Linux; U; Android 4.0; en-us; GT-I9300 Build/IMM76D) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30",
      viewport: {
        width: 640,
        height: 360,
        device_scale_factor: 2,
        is_mobile: true,
        has_touch: true,
        is_landscape: true
      }
    },
    "Galaxy S5" => {
      user_agent: "Mozilla/5.0 (Linux; Android 5.0; SM-G900P Build/LRX21T) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3765.0 Mobile Safari/537.36",
      viewport: {
        width: 360,
        height: 640,
        device_scale_factor: 3,
        is_mobile: true,
        has_touch: true,
        is_landscape: false
      }
    },
    "Galaxy S5 landscape" => {
      user_agent: "Mozilla/5.0 (Linux; Android 5.0; SM-G900P Build/LRX21T) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3765.0 Mobile Safari/537.36",
      viewport: {
        width: 640,
        height: 360,
        device_scale_factor: 3,
        is_mobile: true,
        has_touch: true,
        is_landscape: true
      }
    },
    "iPad" => {
      user_agent: "Mozilla/5.0 (iPad; CPU OS 11_0 like Mac OS X) AppleWebKit/604.1.34 (KHTML, like Gecko) Version/11.0 Mobile/15A5341f Safari/604.1",
      viewport: {
        width: 768,
        height: 1024,
        device_scale_factor: 2,
        is_mobile: true,
        has_touch: true,
        is_landscape: false
      }
    },
    "iPad landscape" => {
      user_agent: "Mozilla/5.0 (iPad; CPU OS 11_0 like Mac OS X) AppleWebKit/604.1.34 (KHTML, like Gecko) Version/11.0 Mobile/15A5341f Safari/604.1",
      viewport: {
        width: 1024,
        height: 768,
        device_scale_factor: 2,
        is_mobile: true,
        has_touch: true,
        is_landscape: true
      }
    },
    "iPad Mini" => {
      user_agent: "Mozilla/5.0 (iPad; CPU OS 11_0 like Mac OS X) AppleWebKit/604.1.34 (KHTML, like Gecko) Version/11.0 Mobile/15A5341f Safari/604.1",
      viewport: {
        width: 768,
        height: 1024,
        device_scale_factor: 2,
        is_mobile: true,
        has_touch: true,
        is_landscape: false
      }
    },
    "iPad Mini landscape" => {
      user_agent: "Mozilla/5.0 (iPad; CPU OS 11_0 like Mac OS X) AppleWebKit/604.1.34 (KHTML, like Gecko) Version/11.0 Mobile/15A5341f Safari/604.1",
      viewport: {
        width: 1024,
        height: 768,
        device_scale_factor: 2,
        is_mobile: true,
        has_touch: true,
        is_landscape: true
      }
    },
    "iPad Pro" => {
      user_agent: "Mozilla/5.0 (iPad; CPU OS 11_0 like Mac OS X) AppleWebKit/604.1.34 (KHTML, like Gecko) Version/11.0 Mobile/15A5341f Safari/604.1",
      viewport: {
        width: 1024,
        height: 1366,
        device_scale_factor: 2,
        is_mobile: true,
        has_touch: true,
        is_landscape: false
      }
    },
    "iPad Pro landscape" => {
      user_agent: "Mozilla/5.0 (iPad; CPU OS 11_0 like Mac OS X) AppleWebKit/604.1.34 (KHTML, like Gecko) Version/11.0 Mobile/15A5341f Safari/604.1",
      viewport: {
        width: 1366,
        height: 1024,
        device_scale_factor: 2,
        is_mobile: true,
        has_touch: true,
        is_landscape: true
      }
    },
    "iPhone 4" => {
      user_agent: "Mozilla/5.0 (iPhone; CPU iPhone OS 7_1_2 like Mac OS X) AppleWebKit/537.51.2 (KHTML, like Gecko) Version/7.0 Mobile/11D257 Safari/9537.53",
      viewport: {
        width: 320,
        height: 480,
        device_scale_factor: 2,
        is_mobile: true,
        has_touch: true,
        is_landscape: false
      }
    },
    "iPhone 4 landscape" => {
      user_agent: "Mozilla/5.0 (iPhone; CPU iPhone OS 7_1_2 like Mac OS X) AppleWebKit/537.51.2 (KHTML, like Gecko) Version/7.0 Mobile/11D257 Safari/9537.53",
      viewport: {
        width: 480,
        height: 320,
        device_scale_factor: 2,
        is_mobile: true,
        has_touch: true,
        is_landscape: true
      }
    },
    "iPhone 5" => {
      user_agent: "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3_1 like Mac OS X) AppleWebKit/603.1.30 (KHTML, like Gecko) Version/10.0 Mobile/14E304 Safari/602.1",
      viewport: {
        width: 320,
        height: 568,
        device_scale_factor: 2,
        is_mobile: true,
        has_touch: true,
        is_landscape: false
      }
    },
    "iPhone 5 landscape" => {
      user_agent: "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3_1 like Mac OS X) AppleWebKit/603.1.30 (KHTML, like Gecko) Version/10.0 Mobile/14E304 Safari/602.1",
      viewport: {
        width: 568,
        height: 320,
        device_scale_factor: 2,
        is_mobile: true,
        has_touch: true,
        is_landscape: true
      }
    },
    "iPhone 6" => {
      user_agent: "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1",
      viewport: {
        width: 375,
        height: 667,
        device_scale_factor: 2,
        is_mobile: true,
        has_touch: true,
        is_landscape: false
      }
    },
    "iPhone 6 landscape" => {
      user_agent: "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1",
      viewport: {
        width: 667,
        height: 375,
        device_scale_factor: 2,
        is_mobile: true,
        has_touch: true,
        is_landscape: true
      }
    },
    "iPhone 6 Plus" => {
      user_agent: "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1",
      viewport: {
        width: 414,
        height: 736,
        device_scale_factor: 3,
        is_mobile: true,
        has_touch: true,
        is_landscape: false
      }
    },
    "iPhone 6 Plus landscape" => {
      user_agent: "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1",
      viewport: {
        width: 736,
        height: 414,
        device_scale_factor: 3,
        is_mobile: true,
        has_touch: true,
        is_landscape: true
      }
    },
    "iPhone 7" => {
      user_agent: "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1",
      viewport: {
        width: 375,
        height: 667,
        device_scale_factor: 2,
        is_mobile: true,
        has_touch: true,
        is_landscape: false
      }
    },
    "iPhone 7 landscape" => {
      user_agent: "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1",
      viewport: {
        width: 667,
        height: 375,
        device_scale_factor: 2,
        is_mobile: true,
        has_touch: true,
        is_landscape: true
      }
    },
    "iPhone 7 Plus" => {
      user_agent: "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1",
      viewport: {
        width: 414,
        height: 736,
        device_scale_factor: 3,
        is_mobile: true,
        has_touch: true,
        is_landscape: false
      }
    },
    "iPhone 7 Plus landscape" => {
      user_agent: "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1",
      viewport: {
        width: 736,
        height: 414,
        device_scale_factor: 3,
        is_mobile: true,
        has_touch: true,
        is_landscape: true
      }
    },
    "iPhone 8" => {
      user_agent: "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1",
      viewport: {
        width: 375,
        height: 667,
        device_scale_factor: 2,
        is_mobile: true,
        has_touch: true,
        is_landscape: false
      }
    },
    "iPhone 8 landscape" => {
      user_agent: "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1",
      viewport: {
        width: 667,
        height: 375,
        device_scale_factor: 2,
        is_mobile: true,
        has_touch: true,
        is_landscape: true
      }
    },
    "iPhone 8 Plus" => {
      user_agent: "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1",
      viewport: {
        width: 414,
        height: 736,
        device_scale_factor: 3,
        is_mobile: true,
        has_touch: true,
        is_landscape: false
      }
    },
    "iPhone 8 Plus landscape" => {
      user_agent: "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1",
      viewport: {
        width: 736,
        height: 414,
        device_scale_factor: 3,
        is_mobile: true,
        has_touch: true,
        is_landscape: true
      }
    },
    "iPhone SE" => {
      user_agent: "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3_1 like Mac OS X) AppleWebKit/603.1.30 (KHTML, like Gecko) Version/10.0 Mobile/14E304 Safari/602.1",
      viewport: {
        width: 320,
        height: 568,
        device_scale_factor: 2,
        is_mobile: true,
        has_touch: true,
        is_landscape: false
      }
    },
    "iPhone SE landscape" => {
      user_agent: "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3_1 like Mac OS X) AppleWebKit/603.1.30 (KHTML, like Gecko) Version/10.0 Mobile/14E304 Safari/602.1",
      viewport: {
        width: 568,
        height: 320,
        device_scale_factor: 2,
        is_mobile: true,
        has_touch: true,
        is_landscape: true
      }
    },
    "iPhone X" => {
      user_agent: "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1",
      viewport: {
        width: 375,
        height: 812,
        device_scale_factor: 3,
        is_mobile: true,
        has_touch: true,
        is_landscape: false
      }
    },
    "iPhone X landscape" => {
      user_agent: "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1",
      viewport: {
        width: 812,
        height: 375,
        device_scale_factor: 3,
        is_mobile: true,
        has_touch: true,
        is_landscape: true
      }
    },
    "JioPhone 2" => {
      user_agent: "Mozilla/5.0 (Mobile; LYF/F300B/LYF-F300B-001-01-15-130718-i;Android; rv:48.0) Gecko/48.0 Firefox/48.0 KAIOS/2.5",
      viewport: {
        width: 240,
        height: 320,
        device_scale_factor: 1,
        is_mobile: true,
        has_touch: true,
        is_landscape: false
      }
    },
    "JioPhone 2 landscape" => {
      user_agent: "Mozilla/5.0 (Mobile; LYF/F300B/LYF-F300B-001-01-15-130718-i;Android; rv:48.0) Gecko/48.0 Firefox/48.0 KAIOS/2.5",
      viewport: {
        width: 320,
        height: 240,
        device_scale_factor: 1,
        is_mobile: true,
        has_touch: true,
        is_landscape: true
      }
    },
    "Kindle Fire HDX" => {
      user_agent: "Mozilla/5.0 (Linux; U; en-us; KFAPWI Build/JDQ39) AppleWebKit/535.19 (KHTML, like Gecko) Silk/3.13 Safari/535.19 Silk-Accelerated=true",
      viewport: {
        width: 800,
        height: 1280,
        device_scale_factor: 2,
        is_mobile: true,
        has_touch: true,
        is_landscape: false
      }
    },
    "Kindle Fire HDX landscape" => {
      user_agent: "Mozilla/5.0 (Linux; U; en-us; KFAPWI Build/JDQ39) AppleWebKit/535.19 (KHTML, like Gecko) Silk/3.13 Safari/535.19 Silk-Accelerated=true",
      viewport: {
        width: 1280,
        height: 800,
        device_scale_factor: 2,
        is_mobile: true,
        has_touch: true,
        is_landscape: true
      }
    },
    "LG Optimus L70" => {
      user_agent: "Mozilla/5.0 (Linux; U; Android 4.4.2; en-us; LGMS323 Build/KOT49I.MS32310c) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/75.0.3765.0 Mobile Safari/537.36",
      viewport: {
        width: 384,
        height: 640,
        device_scale_factor: 1.25,
        is_mobile: true,
        has_touch: true,
        is_landscape: false
      }
    },
    "LG Optimus L70 landscape" => {
      user_agent: "Mozilla/5.0 (Linux; U; Android 4.4.2; en-us; LGMS323 Build/KOT49I.MS32310c) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/75.0.3765.0 Mobile Safari/537.36",
      viewport: {
        width: 640,
        height: 384,
        device_scale_factor: 1.25,
        is_mobile: true,
        has_touch: true,
        is_landscape: true
      }
    },
    "Microsoft Lumia 550" => {
      user_agent: "Mozilla/5.0 (Windows Phone 10.0; Android 4.2.1; Microsoft; Lumia 550) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2486.0 Mobile Safari/537.36 Edge/14.14263",
      viewport: {
        width: 640,
        height: 360,
        device_scale_factor: 2,
        is_mobile: true,
        has_touch: true,
        is_landscape: false
      }
    },
    "Microsoft Lumia 950" => {
      user_agent: "Mozilla/5.0 (Windows Phone 10.0; Android 4.2.1; Microsoft; Lumia 950) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2486.0 Mobile Safari/537.36 Edge/14.14263",
      viewport: {
        width: 360,
        height: 640,
        device_scale_factor: 4,
        is_mobile: true,
        has_touch: true,
        is_landscape: false
      }
    },
    "Microsoft Lumia 950 landscape" => {
      user_agent: "Mozilla/5.0 (Windows Phone 10.0; Android 4.2.1; Microsoft; Lumia 950) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2486.0 Mobile Safari/537.36 Edge/14.14263",
      viewport: {
        width: 640,
        height: 360,
        device_scale_factor: 4,
        is_mobile: true,
        has_touch: true,
        is_landscape: true
      }
    },
    "Nexus 10" => {
      user_agent: "Mozilla/5.0 (Linux; Android 6.0.1; Nexus 10 Build/MOB31T) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3765.0 Safari/537.36",
      viewport: {
        width: 800,
        height: 1280,
        device_scale_factor: 2,
        is_mobile: true,
        has_touch: true,
        is_landscape: false
      }
    },
    "Nexus 10 landscape" => {
      user_agent: "Mozilla/5.0 (Linux; Android 6.0.1; Nexus 10 Build/MOB31T) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3765.0 Safari/537.36",
      viewport: {
        width: 1280,
        height: 800,
        device_scale_factor: 2,
        is_mobile: true,
        has_touch: true,
        is_landscape: true
      }
    },
    "Nexus 4" => {
      user_agent: "Mozilla/5.0 (Linux; Android 4.4.2; Nexus 4 Build/KOT49H) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3765.0 Mobile Safari/537.36",
      viewport: {
        width: 384,
        height: 640,
        device_scale_factor: 2,
        is_mobile: true,
        has_touch: true,
        is_landscape: false
      }
    },
    "Nexus 4 landscape" => {
      user_agent: "Mozilla/5.0 (Linux; Android 4.4.2; Nexus 4 Build/KOT49H) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3765.0 Mobile Safari/537.36",
      viewport: {
        width: 640,
        height: 384,
        device_scale_factor: 2,
        is_mobile: true,
        has_touch: true,
        is_landscape: true
      }
    },
    "Nexus 5" => {
      user_agent: "Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3765.0 Mobile Safari/537.36",
      viewport: {
        width: 360,
        height: 640,
        device_scale_factor: 3,
        is_mobile: true,
        has_touch: true,
        is_landscape: false
      }
    },
    "Nexus 5 landscape" => {
      user_agent: "Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3765.0 Mobile Safari/537.36",
      viewport: {
        width: 640,
        height: 360,
        device_scale_factor: 3,
        is_mobile: true,
        has_touch: true,
        is_landscape: true
      }
    },
    "Nexus 5X" => {
      user_agent: "Mozilla/5.0 (Linux; Android 8.0.0; Nexus 5X Build/OPR4.170623.006) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3765.0 Mobile Safari/537.36",
      viewport: {
        width: 412,
        height: 732,
        device_scale_factor: 2.625,
        is_mobile: true,
        has_touch: true,
        is_landscape: false
      }
    },
    "Nexus 5X landscape" => {
      user_agent: "Mozilla/5.0 (Linux; Android 8.0.0; Nexus 5X Build/OPR4.170623.006) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3765.0 Mobile Safari/537.36",
      viewport: {
        width: 732,
        height: 412,
        device_scale_factor: 2.625,
        is_mobile: true,
        has_touch: true,
        is_landscape: true
      }
    },
    "Nexus 6" => {
      user_agent: "Mozilla/5.0 (Linux; Android 7.1.1; Nexus 6 Build/N6F26U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3765.0 Mobile Safari/537.36",
      viewport: {
        width: 412,
        height: 732,
        device_scale_factor: 3.5,
        is_mobile: true,
        has_touch: true,
        is_landscape: false
      }
    },
    "Nexus 6 landscape" => {
      user_agent: "Mozilla/5.0 (Linux; Android 7.1.1; Nexus 6 Build/N6F26U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3765.0 Mobile Safari/537.36",
      viewport: {
        width: 732,
        height: 412,
        device_scale_factor: 3.5,
        is_mobile: true,
        has_touch: true,
        is_landscape: true
      }
    },
    "Nexus 6P" => {
      user_agent: "Mozilla/5.0 (Linux; Android 8.0.0; Nexus 6P Build/OPP3.170518.006) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3765.0 Mobile Safari/537.36",
      viewport: {
        width: 412,
        height: 732,
        device_scale_factor: 3.5,
        is_mobile: true,
        has_touch: true,
        is_landscape: false
      }
    },
    "Nexus 6P landscape" => {
      user_agent: "Mozilla/5.0 (Linux; Android 8.0.0; Nexus 6P Build/OPP3.170518.006) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3765.0 Mobile Safari/537.36",
      viewport: {
        width: 732,
        height: 412,
        device_scale_factor: 3.5,
        is_mobile: true,
        has_touch: true,
        is_landscape: true
      }
    },
    "Nexus 7" => {
      user_agent: "Mozilla/5.0 (Linux; Android 6.0.1; Nexus 7 Build/MOB30X) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3765.0 Safari/537.36",
      viewport: {
        width: 600,
        height: 960,
        device_scale_factor: 2,
        is_mobile: true,
        has_touch: true,
        is_landscape: false
      }
    },
    "Nexus 7 landscape" => {
      user_agent: "Mozilla/5.0 (Linux; Android 6.0.1; Nexus 7 Build/MOB30X) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3765.0 Safari/537.36",
      viewport: {
        width: 960,
        height: 600,
        device_scale_factor: 2,
        is_mobile: true,
        has_touch: true,
        is_landscape: true
      }
    },
    "Nokia Lumia 520" => {
      user_agent: "Mozilla/5.0 (compatible; MSIE 10.0; Windows Phone 8.0; Trident/6.0; IEMobile/10.0; ARM; Touch; NOKIA; Lumia 520)",
      viewport: {
        width: 320,
        height: 533,
        device_scale_factor: 1.5,
        is_mobile: true,
        has_touch: true,
        is_landscape: false
      }
    },
    "Nokia Lumia 520 landscape" => {
      user_agent: "Mozilla/5.0 (compatible; MSIE 10.0; Windows Phone 8.0; Trident/6.0; IEMobile/10.0; ARM; Touch; NOKIA; Lumia 520)",
      viewport: {
        width: 533,
        height: 320,
        device_scale_factor: 1.5,
        is_mobile: true,
        has_touch: true,
        is_landscape: true
      }
    },
    "Nokia N9" => {
      user_agent: "Mozilla/5.0 (MeeGo; NokiaN9) AppleWebKit/534.13 (KHTML, like Gecko) NokiaBrowser/8.5.0 Mobile Safari/534.13",
      viewport: {
        width: 480,
        height: 854,
        device_scale_factor: 1,
        is_mobile: true,
        has_touch: true,
        is_landscape: false
      }
    },
    "Nokia N9 landscape" => {
      user_agent: "Mozilla/5.0 (MeeGo; NokiaN9) AppleWebKit/534.13 (KHTML, like Gecko) NokiaBrowser/8.5.0 Mobile Safari/534.13",
      viewport: {
        width: 854,
        height: 480,
        device_scale_factor: 1,
        is_mobile: true,
        has_touch: true,
        is_landscape: true
      }
    },
    "Pixel 2" => {
      user_agent: "Mozilla/5.0 (Linux; Android 8.0; Pixel 2 Build/OPD3.170816.012) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3765.0 Mobile Safari/537.36",
      viewport: {
        width: 411,
        height: 731,
        device_scale_factor: 2.625,
        is_mobile: true,
        has_touch: true,
        is_landscape: false
      }
    },
    "Pixel 2 landscape" => {
      user_agent: "Mozilla/5.0 (Linux; Android 8.0; Pixel 2 Build/OPD3.170816.012) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3765.0 Mobile Safari/537.36",
      viewport: {
        width: 731,
        height: 411,
        device_scale_factor: 2.625,
        is_mobile: true,
        has_touch: true,
        is_landscape: true
      }
    },
    "Pixel 2 XL" => {
      user_agent: "Mozilla/5.0 (Linux; Android 8.0.0; Pixel 2 XL Build/OPD1.170816.004) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3765.0 Mobile Safari/537.36",
      viewport: {
        width: 411,
        height: 823,
        device_scale_factor: 3.5,
        is_mobile: true,
        has_touch: true,
        is_landscape: false
      }
    },
    "Pixel 2 XL landscape" => {
      user_agent: "Mozilla/5.0 (Linux; Android 8.0.0; Pixel 2 XL Build/OPD1.170816.004) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3765.0 Mobile Safari/537.36",
      viewport: {
        width: 823,
        height: 411,
        device_scale_factor: 3.5,
        is_mobile: true,
        has_touch: true,
        is_landscape: true
      }
    }
  }.freeze
  private_constant :DEVICE_DESCRIPTORS
end
