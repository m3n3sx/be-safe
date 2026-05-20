/**
 * be:Safe marker icon library.
 *
 * Provides:
 *  - Material Symbols Outlined path data (white, sourced from @material-symbols/svg-300, Apache-2.0)
 *  - SVG generators for alert teardrop pins (5 variants), special pins (user / family / child / group / SOS)
 *    and density-aware cluster pins, matching the Serenity Guard design system.
 *
 * All glyph paths use viewBox="0 -960 960 960" (the native Material Symbols coordinate space).
 * The generators inline the glyph and transform it into the pin's coordinate space.
 *
 * Design tokens:
 *   primary-container (navy)  #1A2027
 *   alert-coral               #FF7A7A
 *   secondary-fixed (mint)    #9DF4CB
 *   calm-aqua                 #9EEBEC
 *   outline-variant           #C5C6CB
 *   on-surface-variant        #44474B
 *   inactive desaturated      #B8B8B8
 */


export const SERENITY = {
  navy: '#1A2027',
  coral: '#FF7A7A',
  mint: '#9DF4CB',
  aqua: '#9EEBEC',
  outline: '#C5C6CB',
  inactive: '#B8B8B8',
  white: '#FFFFFF',
} as const;

/* ──────────────────────── Material Symbols path data ────────────────────────
 * Single-path 'd' attribute strings extracted from @material-symbols/svg-300
 * (outlined weight 300). viewBox = "0 -960 960 960".
 * ──────────────────────────────────────────────────────────────────────────── */
export const MATERIAL_SYMBOL_PATHS: Record<string, string> = {
  person_alert:
    'M780.62-540.6q-7.93-7.91-7.93-19.39 0-11.47 7.91-19.39 7.91-7.93 19.39-7.93 11.47 0 19.39 7.91 7.93 7.91 7.93 19.39 0 11.47-7.91 19.39-7.91 7.93-19.39 7.93-11.47 0-19.39-7.91Zm-3.31-116.71v-165.38h45.38v165.38h-45.38Zm-512.62 127q-37.38-37.38-37.38-95.5 0-58.11 37.38-95.3 37.39-37.2 95.31-37.2t95.31 37.2q37.38 37.19 37.38 95.3 0 58.12-37.38 95.5-37.39 37.39-95.31 37.39t-95.31-37.39ZM60-187.69v-75.93q0-30 15.96-55.03 15.96-25.04 45.5-37.89 68.85-30.31 125.23-43.42 56.39-13.12 113.31-13.12t113 13.12q56.08 13.11 124.92 43.42 29.54 13.85 45.81 38.39Q660-293.62 660-263.62v75.93H60Zm45.39-45.39h509.22v-30.54q0-15.61-9.57-29.92-9.58-14.31-26.12-22.46-64.07-29.92-113.34-40.81-49.26-10.88-105.58-10.88t-106.08 10.88Q204.15-345.92 140.46-316q-16.92 8.15-26 22.46-9.07 14.31-9.07 29.92v30.54Zm316.99-330.15q24.93-24.92 24.93-62.38 0-37.47-24.93-62.39-24.92-24.92-62.38-24.92T297.62-688q-24.93 24.92-24.93 62.39 0 37.46 24.93 62.38 24.92 24.92 62.38 24.92t62.38-24.92ZM360-625.61Zm0 392.53Z',
  wallet:
    'M240-180q-57.92 0-98.96-41.04Q100-262.08 100-320v-320q0-57.92 41.04-98.96Q182.08-780 240-780h480q57.92 0 98.96 41.04Q860-697.92 860-640v320q0 57.92-41.04 98.96Q777.92-180 720-180H240Zm0-442.69h480q27.85 0 52 9.58 24.15 9.57 42.61 26.96V-640q0-39.69-27.46-67.15-27.46-27.46-67.15-27.46H240q-39.69 0-67.15 27.46-27.46 27.46-27.46 67.15v53.85q18.46-17.39 42.61-26.96 24.15-9.58 52-9.58Zm-93.15 124.07 472.77 114.23q6.61 1.62 13.92.31t11.92-6.31l159.62-134q-11.46-23.76-34.27-38.34Q748-577.31 720-577.31H240q-35 0-61.23 22.46-26.23 22.46-31.92 56.23Z',
  car_crash:
    'M145.39-228.23v-208.46 208.46ZM100-432.46l82.31-244.85q3.85-10.53 12.92-16.61 9.08-6.08 20.46-6.08h214.92q-1.23 11.16-.65 22.69.58 11.54 1.81 22.7H223l-60 176.77h378.16q32.23 22.99 71.53 34.96 39.31 11.96 82.85 10.42H145.39v204.23h589.22v-212.31q11.23-1.44 23.04-5.68 11.81-4.24 22.35-9.7v333.23q0 9.64-6.53 16.16-6.52 6.53-16.16 6.53h-10.62q-10.06 0-16.06-6.53-6.01-6.52-6.01-16.16v-60.16H155.38v60.16q0 9.64-6.52 16.16-6.52 6.53-16.17 6.53h-10q-9.64 0-16.16-6.53-6.53-6.52-6.53-16.16v-309.77Zm533.71 150.77q20.52 0 34.29-14.11t13.77-34.02q0-20.74-14.11-34.96Q653.55-379 633.76-379q-20.61 0-34.96 14.24-14.34 14.24-14.34 34.88 0 20.65 14.37 34.42 14.36 13.77 34.88 13.77Zm-385.61 0q20.52 0 34.28-14.11 13.77-14.11 13.77-34.02 0-20.74-14.11-34.96Q267.93-379 248.15-379q-20.62 0-34.96 14.24t-14.34 34.88q0 20.65 14.36 34.42 14.37 13.77 34.89 13.77ZM679.05-513q-72.08 0-122.91-50.84-50.83-50.83-50.83-123.49 0-71.62 50.82-122.14Q606.95-860 679.16-860q72.72 0 122.93 50.31 50.22 50.31 50.22 123T801.72-563.5Q751.13-513 679.05-513Zm-14.28-148.69h31.92v-127.62h-31.92v127.62Zm15.96 80.77q8.73 0 14.65-5.81 5.93-5.81 6.31-14.85 0-9.27-6.21-14.96-6.22-5.69-14.25-5.69-10.23.61-15.54 6.23-5.31 5.61-5.31 14.54 0 8.92 5.81 14.73 5.81 5.81 14.54 5.81Z',
  local_fire_department:
    'M225.39-400q0 68.39 34.26 126.96 34.27 58.58 93.74 92.12-6.7-13.54-10.04-28.16Q340-223.69 340-238q0-27.77 10.66-52.31 10.65-24.54 30.57-44.46L480-431.92l99.15 97.15q19.93 19.92 30.39 44.46T620-238q0 14.31-3.35 28.92-3.34 14.62-10.04 28.16 59.47-33.54 93.74-92.12 34.26-58.57 34.26-126.96 0-52.85-21.84-102.62-21.85-49.76-62.54-90.46-20.61 14.62-43.42 22.54-22.81 7.93-45.81 7.93-61.38 0-102.92-41.31T415-708.23v-14.62q-44.08 32.62-79.35 71.47-35.27 38.84-59.73 80.8-24.46 41.97-37.5 85.54-13.03 43.58-13.03 85.04ZM480-368.31l-67.15 66.16q-13.23 13.23-20.35 29.46-7.11 16.23-7.11 34.69 0 38.69 27.46 65.65 27.46 26.96 67.15 26.96 39.69 0 67.15-26.96 27.46-26.96 27.46-65.65 0-18.85-7.11-35.08-7.12-16.23-20.35-29.07L480-368.31Zm-20-435.92V-708q0 42.46 29.27 71.23Q518.54-608 561-608q18.38 0 35.04-6.92 16.65-6.92 30.58-20.39l17.61-17.76q63.23 40.46 99.5 107.96T780-400q0 125.54-87.23 212.77T480-100q-125.54 0-212.77-87.23T180-400q0-115.31 75.04-224.38Q330.08-733.46 460-804.23Z',
  waves:
    'M90-175.23v-45q26.85-3.39 46.08-15.42 19.23-12.04 38.65-24.81 19.42-12.77 43.08-22.62 23.65-9.84 58.54-9.84 34.88 0 60.11 11.53 25.23 11.54 47.12 25.39 21.88 13.85 44.46 25.19 22.58 11.35 51.96 11.35 29.38 0 51.96-11.35 22.58-11.34 44.46-25.19 21.89-13.85 47.12-25.39 25.23-11.53 60.11-11.53 34.89 0 58.23 9.84 23.35 9.85 43.08 22.62 19.73 12.77 38.96 24.81 19.23 12.03 46.08 15.42v45q-30.77-2.77-52.54-14.31-21.77-11.54-41.69-24.5-19.92-12.96-41.31-23.42-21.38-10.46-50.61-10.46-29.62 0-52.5 11.53-22.89 11.54-44.97 25.2-22.07 13.65-47.19 25.19-25.11 11.54-59.19 11.54T420.81-186q-25.12-11.54-47.19-25.19-22.08-13.66-44.97-25.2-22.88-11.53-52.3-11.53-29.43 0-51.12 10.46-21.69 10.46-41.31 23.42-19.61 12.96-41.38 24.5Q120.77-178 90-175.23Zm0-164.08v-45q26.85-3.77 46.08-15.61 19.23-11.85 38.65-24.81 19.42-12.96 43.08-22.62 23.65-9.65 58.54-9.65 34.88 0 60.11 11.54 25.23 11.54 47.12 25.19 21.88 13.65 44.46 25.19 22.58 11.54 51.96 11.54 29.38 0 51.96-11.54 22.58-11.54 44.46-25.19 21.89-13.65 47.12-25.19Q648.77-457 683.85-457q34.69 0 58.03 9.65 23.35 9.66 43.08 22.62 19.73 12.96 38.96 24.81 19.23 11.84 46.08 15.61v45q-30.77-4.38-52.54-16.23-21.77-11.85-41.69-24.5-19.92-12.65-41.31-22.5-21.38-9.85-50.61-9.85-29.62 0-52.2 11.54-22.57 11.54-44.77 25.39-22.19 13.84-47.5 25.38-25.3 11.54-59.38 11.54t-59.19-11.54q-25.12-11.54-47.19-25.38-22.08-13.85-44.97-25.39-22.88-11.54-52.3-11.54-29.43 0-51.12 10.66-21.69 10.65-41.31 23.61-19.61 12.96-41.38 24.5-21.77 11.54-52.54 14.31Zm0-164.46v-44.61q26.85-3.16 46.08-14.7 19.23-11.53 38.65-24.5 19.42-12.96 43.08-23.42 23.65-10.46 58.54-10.46 34.88 0 60.11 11.54 25.23 11.54 47.12 25.38 21.88 13.85 44.46 25.39 22.58 11.54 51.96 11.54 29.38 0 51.96-11.54 22.58-11.54 44.46-25.39 21.89-13.84 47.12-25.38 25.23-11.54 60.31-11.54 34.69 0 58.03 10.46 23.35 10.46 43.08 23.42 19.73 12.97 38.96 24.5 19.23 11.54 46.08 14.7v44.61q-30.77-2.38-52.54-13.92t-41.69-24.69q-19.92-13.16-41.31-23.62-21.38-10.46-50.61-10.46-29.62 0-52.5 11.54-22.89 11.54-44.97 25.19-22.07 13.65-47.19 25.19Q514.08-503 480-503t-59.19-11.54q-25.12-11.54-47.19-25.19-22.08-13.65-44.97-25.19-22.88-11.54-52.3-11.54-29.43 0-51.12 10.46-21.69 10.46-41.31 23.62-19.61 13.15-41.38 24.69-21.77 11.54-52.54 13.92Zm0-164.08v-44.99q26.85-3.77 46.08-15.62 19.23-11.85 38.65-24.62 19.42-12.76 43.08-22.61 23.65-9.85 58.54-9.85 34.88 0 60.11 11.54 25.23 11.54 47.12 25.19 21.88 13.66 44.46 25.2 22.58 11.53 51.96 11.53 29.38 0 51.96-11.53 22.58-11.54 44.46-25.2 21.89-13.65 47.12-25.19 25.23-11.54 60.31-11.54 34.69 0 58.03 9.85 23.35 9.85 43.08 22.61 19.73 12.77 38.96 24.62 19.23 11.85 46.08 15.62v44.99q-30.77-2.76-52.54-14.3-21.77-11.54-41.69-24.5-19.92-12.96-41.31-23.43-21.38-10.46-50.61-10.46-29.62 0-52.5 11.35-22.89 11.34-44.97 25.19-22.07 13.85-47.19 25.39-25.11 11.53-59.19 11.53t-59.19-11.53q-25.12-11.54-47.19-25.39-22.08-13.85-44.97-25.19-22.88-11.35-52.3-11.35-29.43 0-51.12 10.46-21.69 10.47-41.31 23.43-19.61 12.96-41.38 24.5-21.77 11.54-52.54 14.3Z',
  severe_cold:
    'M807.31-577.31q-9.31 0-16-6.69-6.69-6.69-6.69-16 0-9.92 6.69-16.31 6.69-6.38 16-6.38 9.92 0 16.3 6.38Q830-609.92 830-600q0 9.31-6.39 16-6.38 6.69-16.3 6.69ZM410-90v-168.39L288.69-137.08l-31.61-31.61L410-321.62V-410h-88.38L168.69-257.08l-31.61-31.61L258.39-410H90v-45.38h168.39L137.08-576.69l31.61-31.62 152.93 152.93H410v-88.39L257.08-696.69l31.61-31.62L410-607v-168.38h45.38V-607l121.31-121.31 31.62 31.62-152.93 152.92v88.39h320V-410H607l121.31 121.31-31.62 31.61L543.77-410h-88.39v88.38l152.93 152.93-31.62 31.61-121.31-121.31V-90H410Zm374.62-602.69V-870H830v177.31h-45.38Z',
  warning:
    'M74.62-140 480-840l405.38 700H74.62Zm78.61-45.39h653.54L480-749.23 153.23-185.39Zm347.46-67.41q7.16-7.33 7.16-17.84t-7.34-17.67q-7.34-7.15-17.85-7.15-10.51 0-17.66 7.33-7.15 7.34-7.15 17.85 0 10.51 7.33 17.66 7.34 7.16 17.85 7.16 10.51 0 17.66-7.34Zm-40.54-90.58h45.39v-217.85h-45.39v217.85ZM480-467.31Z',
  pets:
    'M172.56-492.31q-34.79 0-58.67-24.02Q90-540.35 90-575.14q0-34.78 24.02-58.67 24.02-23.88 58.81-23.88 34.79 0 58.67 24.02 23.88 24.02 23.88 58.81 0 34.78-24.02 58.67-24.02 23.88-58.8 23.88Zm125.11-191.33q-23.82-24.02-23.82-58.8 0-34.79 24.01-58.67Q321.88-825 356.66-825q34.42 0 58.49 24.02 24.08 24.02 24.08 58.81 0 34.79-24.2 58.67-24.19 23.88-58.87 23.88-34.67 0-58.49-24.02Zm247.31 0q-23.83-24.02-23.83-58.8 0-34.79 24.02-58.67Q569.18-825 603.97-825q34.41 0 58.49 24.02 24.08 24.02 24.08 58.81 0 34.79-24.2 58.67-24.19 23.88-58.87 23.88-34.67 0-58.49-24.02Zm242.19 191.33q-34.79 0-58.67-24.02-23.88-24.02-23.88-58.81 0-34.78 24.02-58.67 24.02-23.88 58.8-23.88 34.79 0 58.67 24.02Q870-609.65 870-574.86q0 34.78-24.02 58.67-24.02 23.88-58.81 23.88ZM266-85q-38.92 0-63.81-29.35-24.88-29.36-24.88-69.34 0-42.93 27.81-75.16 27.8-32.23 56.8-63.38 23.93-24.69 43.7-52.08 19.77-27.38 39.46-55.31 25.92-37.46 58.13-69.11T480-530.38q45.01 0 77.89 31.65t58.42 70.11q20.07 27.54 39.15 54.81 19.08 27.27 42.62 51.58 29 31.15 56.8 63.38 27.81 32.23 27.81 75.16 0 39.98-24.88 69.34Q732.92-85 694-85q-54 0-107-9t-107-9q-54 0-107 9t-107 9Z',
  dark_mode:
    'M481.15-140q-141.66 0-240.83-99.17-99.16-99.16-99.16-240.83 0-135.77 92.11-232.88 92.11-97.12 225.57-105.2 4.16 0 9.12.31 4.96.31 13.96.49-27.15 30.9-41.96 71.74-14.81 40.85-14.81 85.54 0 98.33 68.84 167.17Q562.82-424 661.15-424q44.31 0 85.35-13.69 41.04-13.69 71.5-38.61.23 7.38.54 11.23.3 3.84.3 7.38-7.69 133.46-104.8 225.57Q616.92-140 481.15-140Zm0-45.39q103.23 0 181.35-62.49 78.11-62.5 101.19-149.66-23.46 9.46-49.82 14.19-26.36 4.74-52.72 4.74-116.92 0-199.15-82.23T379.77-660q0-23.23 4.42-48.62 4.42-25.38 15.5-56.15-92.61 28.16-152.88 107.47-60.27 79.31-60.27 177.3 0 122.77 85.92 208.69t208.69 85.92Zm-5.53-289.69Z',
  vaccines:
    'm302.69-80-45.38-34.23v-183.08h-74.62q-18.91 0-32.15-13.23-13.23-13.24-13.23-32.15v-334.62H120q-9.89 0-16.29-6.4-6.4-6.41-6.4-16.31 0-9.9 6.4-16.29 6.4-6.38 16.29-6.38h137.31v-101.93H220q-9.89 0-16.29-6.4-6.4-6.41-6.4-16.31 0-9.9 6.4-16.28Q210.11-870 220-870h120q9.89 0 16.29 6.41 6.4 6.4 6.4 16.3 0 9.91-6.4 16.29-6.4 6.38-16.29 6.38h-37.31v101.93H440q9.89 0 16.29 6.4 6.4 6.41 6.4 16.31 0 9.9-6.4 16.29-6.4 6.38-16.29 6.38h-17.31v334.62q0 18.91-13.23 32.15-13.24 13.23-32.15 13.23h-74.62V-80Zm-120-262.69h194.62v-90.77H290q-6.62 0-11.58-4.9t-4.96-11.69q0-6.8 4.96-11.64 4.96-4.85 11.58-4.85h87.31v-86.92H290q-6.62 0-11.58-4.9t-4.96-11.69q0-6.8 4.96-11.64 4.96-4.85 11.58-4.85h87.31v-90.77H182.69v334.62ZM590-90q-18.91 0-32.15-13.24-13.23-13.23-13.23-32.14v-274.47q0-30.68 9.73-47.84 9.73-17.16 21.96-30.39 16.31-17.3 22.31-27.92 6-10.62 6-24v-37.31h-17.31q-9.9 0-16.3-6.4-6.39-6.41-6.39-16.31 0-9.9 6.7-16.29 6.7-6.38 15.99-6.38h200q9.89 0 16.29 6.4 6.4 6.41 6.4 16.31 0 9.9-6.4 16.29-6.4 6.38-16.29 6.38H770v37.26q0 12.82 6.92 24.67 6.93 11.84 23.23 29.15 12.62 13.23 21.23 29.19 8.62 15.96 8.62 47.05v274.61q0 18.91-13.24 32.14Q803.53-90 784.62-90H590Zm0-289.23h194.62v-30.81q0-19.29-9.81-33.7-9.81-14.41-22.19-29.03-13.58-16.57-20.79-31.48-7.21-14.9-7.21-35.75v-37.31H650V-540q0 20.12-6.96 35.02-6.96 14.9-20.43 31.59-12.48 14.61-22.55 29.37Q590-429.25 590-409.85v30.62Zm0 120h194.62v-86.92H590v86.92Zm0 123.85h194.62v-90.77H590v90.77Zm0-123.85h194.62H590Z',
  local_police:
    'M387.08-368.39 480-437.92l90.31 68.76-37.23-110.99 94.46-68.7H514.15L480-659.61l-34.15 110.76H332.46l92.46 68.7-37.84 111.76Zm92.92 267q-130.38-35.77-215.19-155.19Q180-376 180-521.08v-225.69l300-112.31 300 112.31v225.69q0 145.08-84.81 264.5Q610.38-137.16 480-101.39Zm0-47.38Q591.92-185.23 663.27-289q71.34-103.77 71.34-232.08v-194.07L480-810.85l-254.61 95.7v194.07q0 128.31 71.34 232.08Q368.08-185.23 480-148.77Zm0-330.85Z',
  thunderstorm:
    'M318.08-63.08 351-156.16h-69.84l46.15-129.23h84.61l-39.53 92.31h76.46l-101.54 130h-29.23ZM567.31-100l26.07-74.62h-72.23l39.54-110.77h84.62l-31.93 73.85h75.46L596.54-100h-29.23ZM292.69-344.62q-83.78 0-143.24-59.4Q90-463.42 90-547.14q0-77.63 54.58-136.74 54.57-59.12 137.04-65.5 30.84-56 82.19-88.31Q415.15-870 480.26-870q88.43 0 148.97 57.31 60.54 57.31 72.62 142.31 79 3.61 123.57 51.38Q870-571.23 870-507.53q0 67.53-47.48 115.22-47.49 47.69-115.21 47.69H292.69Zm0-45.38h414.62q48.91 0 83.11-34.61 34.2-34.62 34.2-83.01 0-48.38-34.2-82.69-34.2-34.31-83.11-34.31h-50v-22.69q0-73.69-51.81-125.5t-125.29-51.81q-53.68 0-97.83 28.85T317.08-718l-5.7 13.38h-20.75q-64.63 2-109.94 47.49-45.31 45.48-45.31 109.66 0 65.24 46.03 111.36Q227.43-390 292.69-390ZM480-607.31Z',
  more_horiz:
    'M225.55-443.54q-15.1 0-25.71-10.75-10.61-10.74-10.61-25.83 0-15.09 10.75-25.72 10.74-10.62 25.83-10.62 15.09 0 25.91 10.75 10.82 10.74 10.82 25.83 0 15.09-10.87 25.72-10.86 10.62-26.12 10.62Zm254.33 0q-15.09 0-25.72-10.75-10.62-10.74-10.62-25.83 0-15.09 10.75-25.72 10.74-10.62 25.83-10.62 15.09 0 25.72 10.75 10.62 10.74 10.62 25.83 0 15.09-10.75 25.72-10.74 10.62-25.83 10.62Zm254.31 0q-15.09 0-25.91-10.75-10.82-10.74-10.82-25.83 0-15.09 10.87-25.72 10.86-10.62 26.12-10.62 15.1 0 25.71 10.75 10.61 10.74 10.61 25.83 0 15.09-10.75 25.72-10.74 10.62-25.83 10.62Z',
  visibility:
    'M590.31-389.78q45.46-45.56 45.46-110.31 0-64.76-45.55-110.22-45.56-45.46-110.31-45.46-64.76 0-110.22 45.55-45.46 45.56-45.46 110.31 0 64.76 45.55 110.22 45.56 45.46 110.31 45.46 64.76 0 110.22-45.55Zm-189.04-31.49q-32.12-32.11-32.12-78.73 0-46.62 32.12-78.73 32.11-32.12 78.73-32.12 46.62 0 78.73 32.12 32.12 32.11 32.12 78.73 0 46.62-32.12 78.73-32.11 32.12-78.73 32.12-46.62 0-78.73-32.12ZM230.23-297.04Q118-374.08 61.54-500 118-625.92 230.18-702.96 342.35-780 479.95-780q137.59 0 249.82 77.04Q842-625.92 898.46-500 842-374.08 729.82-297.04 617.65-220 480.05-220q-137.59 0-249.82-77.04ZM480-500Zm218.65 170.85Q798.23-392.92 850.46-500q-52.23-107.08-151.81-170.85-99.57-63.76-218.65-63.76-119.08 0-218.65 63.76Q161.77-607.08 108.92-500q52.85 107.08 152.43 170.85 99.57 63.76 218.65 63.76 119.08 0 218.65-63.76Z',
  traffic:
    'M514.65-258.03q14.89-14.79 14.89-36.19 0-21.01-14.8-35.9Q499.95-345 478.94-345q-21.02 0-35.9 14.8-14.89 14.79-14.89 35.8 0 21.4 14.8 36.28 14.79 14.89 35.81 14.89 21.01 0 35.89-14.8Zm0-186.07q14.89-14.8 14.89-35.81t-14.8-35.9q-14.79-14.88-35.8-14.88-21.02 0-35.9 14.79-14.89 14.8-14.89 35.81t14.8 35.9q14.79 14.88 35.81 14.88 21.01 0 35.89-14.79Zm0-185.7q14.89-14.79 14.89-36 0-21.2-14.8-36.08-14.79-14.89-35.8-14.89-21.02 0-35.9 14.8-14.89 14.79-14.89 36 0 21.2 14.8 36.09Q457.74-615 478.76-615q21.01 0 35.89-14.8ZM295.39-345.85v-94.61q-44.85-9.46-69.93-39.23-25.07-29.77-25.07-63.54h95V-636q-44.85-9.08-69.93-38.54-25.07-29.46-25.07-63.23h95v-35.92q0-21.77 12.85-34.04Q321.1-820 340.77-820h276.54q19.29 0 32.33 12.27 13.05 12.27 13.05 34.04v35.92h96.92q0 33.77-26.23 63.23-26.23 29.46-70.69 38.54v92.77h96.92q0 33.77-26.23 63.54-26.23 29.77-70.69 39.23v94.61h96.92q0 35-26.23 63.85-26.23 28.84-70.69 37.92v58.69q0 19.68-13.05 32.53Q636.6-140 617.31-140H340.77q-19.67 0-32.53-12.86-12.85-12.85-12.85-32.53v-58.69q-44.85-9.08-69.93-37.92-25.07-28.85-25.07-63.85h95Zm45.38 160.46h276.54v-589.22H340.77v589.22Zm0 0v-589.22 589.22Z',
  child_friendly:
    'M333.04-129.96q-14.58-14.58-14.58-34.89 0-19.92 14.58-34.69 14.58-14.77 34.69-14.77 20.12 0 34.69 14.77Q417-184.77 417-164.85q0 20.31-14.58 34.89-14.57 14.57-34.69 14.57-20.11 0-34.69-14.57Zm376.65 0q-14.77-14.58-14.77-34.89 0-19.92 14.77-34.69 14.77-14.77 34.88-14.77 20.12 0 34.7 14.77 14.57 14.77 14.57 34.69 0 20.31-14.57 34.89-14.58 14.57-34.7 14.57-20.11 0-34.88-14.57ZM522.54-636.23 383.15-803.54q35.08-15.92 73.04-23.69 37.96-7.77 71.5-7.77 46.77 0 89.58 11.27 42.8 11.27 80.19 34.66L522.54-636.23ZM493-260q-73.31 0-123.61-50.31-50.31-50.31-50.31-124V-714l-30.54-35.31q-28-32.77-45.04-44.42-17.04-11.65-33.96-11.65-29.85 0-46.23 22.07-16.39 22.08-16.39 49.7h-45.38q0-48.31 31.77-82.73 31.77-34.43 77-34.43 28.23 0 52 13.46 23.77 13.47 58.07 55.77l388.39 464.85q13.84 16.07 4.11 36.38Q703.15-260 681.23-260H493Zm0-45.39h164.54l-293.08-353.3v224.38q0 55.08 36.92 92 36.93 36.92 91.62 36.92Zm18-177.15Z',
  water:
    'M90-263.31v-46.15q34.54-1.92 56.12-22.42 21.57-20.5 65.03-20.5 44.62 0 68.85 25.07 24.23 25.08 64.77 25.08 40.54 0 65.58-25.08 25.03-25.07 69.65-25.07 45 0 69.35 25.07 24.34 25.08 64.88 25.08 40.54 0 65.27-25.08 24.73-25.07 69.35-25.07 43.46 0 65.03 20.5 21.58 20.5 56.12 22.42v46.15q-39.31-2.31-61.81-23T748.85-307q-39.16 0-64.39 25.08-25.23 25.07-70.23 25.07-44.61 0-69.46-25.07Q519.92-307 480-307q-39.54 0-64.88 25.08-25.35 25.07-70.35 25.07-44.62 0-69.54-25.07Q250.31-307 211.15-307q-37.23 0-59.34 20.69-22.12 20.69-61.81 23Zm0-155.38v-46.16q34.54-1.92 56.12-22.42 21.57-20.5 65.03-20.5 44.62 0 68.85 25.08 24.23 25.08 64.77 25.08 40.54 0 65.58-25.08 25.03-25.08 69.65-25.08 45 0 69.35 25.08 24.34 25.08 65.27 25.08 40.53 0 65.07-25.08 24.54-25.08 69.16-25.08 43.84 0 65.23 20.5 21.38 20.5 55.92 22.42v46.16q-39.31-2.31-61.81-23-22.5-20.7-59.34-20.7-39.16 0-64.39 25.08-25.23 25.08-70.23 25.08-44.61 0-69.46-25.08-24.85-25.08-64.77-25.08-39.54 0-65.08 25.08t-70.15 25.08q-44.62 0-69.54-25.08-24.92-25.08-64.08-25.08-37.61 0-59.34 20.7-21.73 20.69-61.81 23Zm0-155.39v-46.15q34.54-1.92 56.12-22.42 21.57-20.5 65.03-20.5 44.62 0 68.85 25.07Q304.23-613 344.77-613q40.54 0 65.58-25.08 25.03-25.07 69.65-25.07 45 0 69.35 25.07Q573.69-613 614.62-613q40.53 0 65.07-25.08 24.54-25.07 69.16-25.07 43.84 0 65.23 20.5 21.38 20.5 55.92 22.42v46.15q-39.31-2.31-61.81-23t-59.34-20.69q-39.16 0-64.39 25.08-25.23 25.07-70.23 25.07-44.61 0-69.46-25.07-24.85-25.08-64.77-25.08-39.54 0-65.08 25.08-25.54 25.07-70.15 25.07-44.62 0-69.54-25.07-24.92-25.08-64.08-25.08-37.61 0-59.73 20.69-22.11 20.69-61.42 23Z',
  school:
    'm479.38-166.16-267.3-146.3v-216.93L81.54-600l397.84-216.92L878.46-600v285.46h-45.39v-258.92l-86.38 44.07v216.93l-267.31 146.3Zm0-268.38L782.85-600 479.38-763.23 177.15-600l302.23 165.46Zm0 216.92 221.93-122v-162.23l-221.93 118.7-221.92-120.31v163.84l221.92 122Zm.62-216.92Zm-.62 60.54Zm0 0Z',
  child_care:
    'M619.23-372.31q24.69 0 42.12-17.42 17.42-17.42 17.42-42.12t-17.42-42.12q-17.43-17.42-42.12-17.42-24.7 0-42.12 17.42-17.42 17.42-17.42 42.12t17.42 42.12q17.42 17.42 42.12 17.42Zm-278.46 0q24.69 0 42.11-17.42 17.43-17.42 17.43-42.12t-17.43-42.12q-17.42-17.42-42.11-17.42-24.7 0-42.12 17.42-17.42 17.42-17.42 42.12t17.42 42.12q17.42 17.42 42.12 17.42Zm139.69 137.69q60.62 0 110.96-32.69 50.35-32.69 78.27-87 5.62-10.85 1-22-4.61-11.15-16.46-12.69-37.46-5.92-71.43-21-33.96-15.07-63.04-39.84-22 25.62-49.65 45.65-27.65 20.04-60.42 32.04-29.31 11.23-60.42 16.65-31.12 5.43-62.43 5.81-12.61.85-18.34 11.92-5.73 11.07-.43 21.92 27.92 53.54 78.65 87.39 50.74 33.84 113.74 33.84ZM480.07-100q-78.92 0-148.38-29.92t-120.84-81.31q-51.39-51.38-81.12-120.81Q100-401.46 100-480.31q0-78.84 29.92-148.27 29.93-69.42 81.31-120.81Q262.62-800.77 332.04-830 401.46-859.23 480-859.23q47.62 0 90.31 11.46 42.69 11.46 81.46 32.62 32-47.16 79.78-71.66 47.79-24.5 100.99-24.5 5.07 0 9.92.47 4.85.46 9.69 1v45.78q-5.07-.62-9.92-.7-4.85-.07-9.69-.07-45.85 0-87.04 21.07-41.19 21.08-69.81 60.61 56.62 41.85 90.85 101.27 34.23 59.42 41.07 124.5-1.85-.27.31.04 2.15.31 7.84.69 23.16 4.31 41.42 13.69t31.18 22.65q12.93 13.28 19.04 30.93 6.12 17.65 6.12 36.31 0 18.92-7.27 36.07-7.27 17.16-21.61 31.16-6.66 6.66-15.34 11.66t-17.59 8.7q-22.69 50.31-58.5 90.61-35.81 40.31-81.5 68.85t-99.31 44.42q-53.62 15.88-111.85 15.88Zm0-45.38q140.46 0 240.81-90.81 100.34-90.81 113.5-227.96l1.07-12.85 12.7-2q23.46-3.31 38.96-21.96 15.5-18.66 15.5-43.16 0-25.42-15.86-43.96-15.86-18.54-39.45-22.69l-12.62-1.69-.84-12.85q-9.31-126.46-105.46-216.27Q633.31-731.31 504.5-734.85q-128.81-3.53-220.81 79.85-92 83.38-110.46 207.31-2.16 14-3.27 24.65-1.12 10.66-1.5 22.66-2.31 22.07.96 53.46t12.81 60.31q9.54 28.92 25.04 56.34 15.5 27.43 35.04 50.66 39.46 47.07 96.61 75.15 57.16 28.08 142.15 28.08Zm21.7-411.85Z',
};

/* ──────────────────────── Helpers ────────────────────────────────────────── */

function svgEscape(str: string): string {
  // Suitable for embedding within a data URI without encoding overhead.
  return str.replace(/"/g, "'");
}

export function dataUri(svg: string): string {
  return `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(svgEscape(svg))}`;
}

/**
 * Wrap a Material Symbol path so that the entire 960×960 native viewBox is
 * placed inside a `size`×`size` square anchored at (x,y). The fill is `color`.
 */
function inlineSymbol(symbol: string, x: number, y: number, size: number, color: string = '#FFFFFF'): string {
  const path = MATERIAL_SYMBOL_PATHS[symbol] ?? MATERIAL_SYMBOL_PATHS.more_horiz;
  const scale = size / 960;
  // The native viewBox is "0 -960 960 960" — i.e. coordinates run from
  // (0,-960) at top-left to (960,0) at bottom-right. After scaling by
  // `scale` we get a 0..size square. We translate to (x,y) and shift Y by
  // +size so the path lands within the visible area.
  return `<g transform="translate(${x} ${y + size}) scale(${scale})"><path d="${path}" fill="${color}"/></g>`;
}

/* ──────────────────────── Alert teardrop pin ────────────────────────────────
 * 64×84 canvas. Halo (80×80) sits behind, anchored at -3px top.
 * Pin tip at x=28, y=80.
 * Inner glyph area: roughly a 32×32 box centered at (28,28).
 * ──────────────────────────────────────────────────────────────────────────── */

export type AlertPinVariant = 'default' | 'selected' | 'confirmed' | 'inactive' | 'multi';

export interface AlertPinOptions {
  materialSymbol: string;
  variant?: AlertPinVariant;
  /** Display count for the 'multi' variant. */
  count?: number;
}

export function buildAlertPinSvg(opts: AlertPinOptions): string {
  const { materialSymbol, variant = 'default', count = 1 } = opts;

  const isInactive = variant === 'inactive';
  const isSelected = variant === 'selected';
  const isConfirmed = variant === 'confirmed';
  const isMulti = variant === 'multi';

  const pinColor = isInactive ? SERENITY.inactive : SERENITY.coral;
  const haloColor = isInactive ? SERENITY.inactive : SERENITY.coral;
  const haloOpacity = isSelected ? 0.4 : isInactive ? 0.15 : 0.25;
  const iconOpacity = isInactive ? 0.7 : 1;
  const strokeWidth = 2.5;

  // The whole graphic lives in a 64×84 box so we have room for the halo above.
  const halo = `<circle cx="28" cy="20" r="40" fill="${haloColor}" opacity="${haloOpacity}"/>`;

  // Teardrop path matches the design HTML: tip at (28,80), radius ~28, top arc to y=0
  const teardrop = `<path d="M28 80 C28 80, 56 46.12, 56 28 C56 12.536, 43.464 0, 28 0 C12.536 0, 0 12.536, 0 28 C0 46.12, 28 80, 28 80 Z" fill="${pinColor}" stroke="${SERENITY.white}" stroke-width="${strokeWidth}"/>`;

  // Selected: secondary inner ring (navy at 30%)
  const innerRing = isSelected
    ? `<circle cx="28" cy="28" r="22" fill="none" stroke="${SERENITY.navy}" stroke-opacity="0.3" stroke-width="1.5"/>`
    : '';

  // Glyph: 32×32 box centered at (28,28) ⇒ top-left (12,12)
  const glyph = inlineSymbol(materialSymbol, 12, 12, 32, SERENITY.white).replace(
    '<g ',
    `<g opacity="${iconOpacity}" `,
  );

  // Variant badges (bottom-right of the pin, ≈ (44,40) center)
  let badge = '';
  if (isConfirmed) {
    badge = `
      <g transform="translate(36 32)">
        <circle cx="11" cy="11" r="11" fill="${SERENITY.mint}" stroke="${SERENITY.white}" stroke-width="2"/>
        <path d="M6.5 11.5 L9.5 14.5 L15.5 7.5" stroke="${SERENITY.navy}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
      </g>`;
  } else if (isMulti) {
    const txt = count > 99 ? '99+' : String(count);
    const fontSize = txt.length >= 3 ? 8 : 10;
    badge = `
      <g transform="translate(36 32)">
        <circle cx="11" cy="11" r="11" fill="${SERENITY.navy}" stroke="${SERENITY.white}" stroke-width="2"/>
        <text x="11" y="11" text-anchor="middle" dominant-baseline="central" font-family="Inter, system-ui, -apple-system, sans-serif" font-size="${fontSize}" font-weight="600" fill="${SERENITY.white}">${txt}</text>
      </g>`;
  }

  // Drop shadow (soft, like design: 0 4 8 rgba(26,32,39,0.2))
  const filter = `
    <filter id="pin-shadow" x="-40%" y="-20%" width="180%" height="140%">
      <feDropShadow dx="0" dy="4" stdDeviation="3" flood-color="${SERENITY.navy}" flood-opacity="0.2"/>
    </filter>`;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="64" height="84" viewBox="0 0 64 84">
    <defs>${filter}</defs>
    ${halo}
    <g filter="url(#pin-shadow)" transform="translate(4 0)">
      ${teardrop}
      ${innerRing}
      ${glyph}
    </g>
    ${badge}
  </svg>`;
}

/* ──────────────────────── Special pins ──────────────────────────────────── */

/** User's current position. Calm aqua radial halo + small navy dot. */
export function buildUserPositionSvg(): string {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="56" height="56" viewBox="0 0 56 56">
    <defs>
      <radialGradient id="aqua" cx="50%" cy="50%" r="50%">
        <stop offset="0%" stop-color="${SERENITY.aqua}" stop-opacity="0.5"/>
        <stop offset="70%" stop-color="${SERENITY.aqua}" stop-opacity="0"/>
      </radialGradient>
    </defs>
    <circle cx="28" cy="28" r="28" fill="url(#aqua)"/>
    <circle cx="28" cy="28" r="9" fill="${SERENITY.navy}" stroke="${SERENITY.white}" stroke-width="2"/>
  </svg>`;
}

/** Family member (generic adult). 48×48 mint→navy gradient orb with mint glow. */
export function buildFamilyPinSvg(): string {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
    <defs>
      <linearGradient id="family-grad" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="${SERENITY.mint}"/>
        <stop offset="100%" stop-color="${SERENITY.navy}"/>
      </linearGradient>
      <filter id="family-glow" x="-50%" y="-50%" width="200%" height="200%">
        <feGaussianBlur stdDeviation="3.5" result="blur"/>
        <feFlood flood-color="${SERENITY.mint}" flood-opacity="0.3"/>
        <feComposite in2="blur" operator="in"/>
        <feComposite in="SourceGraphic"/>
      </filter>
    </defs>
    <circle cx="32" cy="32" r="26" fill="${SERENITY.mint}" opacity="0.25"/>
    <circle cx="32" cy="32" r="24" fill="url(#family-grad)" stroke="${SERENITY.mint}" stroke-opacity="0.6" stroke-width="4"/>
  </svg>`;
}

/** Child marker. White circle with navy child_care glyph, mint border + glow. */
export function buildChildPinSvg(): string {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
    <circle cx="32" cy="32" r="26" fill="${SERENITY.mint}" opacity="0.25"/>
    <circle cx="32" cy="32" r="24" fill="${SERENITY.white}" stroke="${SERENITY.mint}" stroke-opacity="0.6" stroke-width="4"/>
    ${inlineSymbol('child_care', 16, 16, 32, SERENITY.navy)}
  </svg>`;
}

/** Group of N members (e.g. multiple kids of one family). Navy circle + mint badge with +1. */
export function buildGroupPinSvg(count: number, extra: number = 1): string {
  const main = count > 99 ? '99+' : String(count);
  const fontSize = main.length >= 3 ? 12 : 16;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
    <defs>
      <filter id="group-shadow" x="-30%" y="-20%" width="160%" height="160%">
        <feDropShadow dx="0" dy="2" stdDeviation="3" flood-color="${SERENITY.navy}" flood-opacity="0.25"/>
      </filter>
    </defs>
    <g filter="url(#group-shadow)">
      <circle cx="32" cy="32" r="24" fill="${SERENITY.navy}"/>
      <text x="32" y="32" text-anchor="middle" dominant-baseline="central" font-family="Inter, system-ui, -apple-system, sans-serif" font-size="${fontSize}" font-weight="500" fill="${SERENITY.white}">${main}</text>
      <g transform="translate(44 44)">
        <circle cx="8" cy="8" r="8" fill="${SERENITY.mint}" stroke="${SERENITY.white}" stroke-width="1.5"/>
        <text x="8" y="8" text-anchor="middle" dominant-baseline="central" font-family="Inter, system-ui, -apple-system, sans-serif" font-size="7" font-weight="700" fill="${SERENITY.white}">+${extra}</text>
      </g>
    </g>
  </svg>`;
}

/** SOS pin. Three concentric coral rings + inner solid disk with 'SOS' text. */
export function buildSosPinSvg(): string {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="80" height="80" viewBox="0 0 80 80">
    <defs>
      <filter id="sos-shadow" x="-30%" y="-30%" width="160%" height="160%">
        <feDropShadow dx="0" dy="3" stdDeviation="4" flood-color="${SERENITY.coral}" flood-opacity="0.5"/>
      </filter>
    </defs>
    <circle cx="40" cy="40" r="32" fill="none" stroke="${SERENITY.coral}" stroke-opacity="0.3" stroke-width="1"/>
    <circle cx="40" cy="40" r="28" fill="none" stroke="${SERENITY.coral}" stroke-opacity="0.6" stroke-width="1"/>
    <circle cx="40" cy="40" r="24" fill="none" stroke="${SERENITY.coral}" stroke-opacity="0.9" stroke-width="1.5"/>
    <g filter="url(#sos-shadow)">
      <circle cx="40" cy="40" r="20" fill="${SERENITY.coral}"/>
      <text x="40" y="40" text-anchor="middle" dominant-baseline="central" font-family="Inter, system-ui, -apple-system, sans-serif" font-size="11" font-weight="600" letter-spacing="0.05em" fill="${SERENITY.white}">SOS</text>
    </g>
  </svg>`;
}

/* ──────────────────────── Flat-circle marker (list / legend / filter chips) ── */

/**
 * Flat-circle marker matching the `refined_map_markers_be_safe` design.
 * Used in legends, filter dropdowns, alert list rows, and anywhere we need
 * a compact category badge that isn't an actual map pin.
 */
export function buildFlatCircleSvg(
  materialSymbol: string,
  opts: { size?: number; dimmed?: boolean } = {}
): string {
  const size = opts.size ?? 56;
  const fill = opts.dimmed ? SERENITY.inactive : SERENITY.coral;
  const opacity = opts.dimmed ? 0.55 : 0.9;
  const haloOpacity = opts.dimmed ? 0.12 : 0.28;
  // Inner disk is 87.5% of outer (56→49 in the reference), glyph 46%
  const inner = size * 0.875;
  const glyph = size * 0.46;
  const c = size / 2;
  const glyphInset = (size - glyph) / 2;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">
    <defs>
      <radialGradient id="flatHalo" cx="50%" cy="50%" r="50%">
        <stop offset="0%" stop-color="${SERENITY.coral}" stop-opacity="${haloOpacity}"/>
        <stop offset="70%" stop-color="${SERENITY.coral}" stop-opacity="0"/>
      </radialGradient>
    </defs>
    <circle cx="${c}" cy="${c}" r="${c}" fill="url(#flatHalo)"/>
    <circle cx="${c}" cy="${c}" r="${inner / 2 - 0.5}" fill="${fill}" fill-opacity="${opacity}"/>
    ${inlineSymbol(materialSymbol, glyphInset, glyphInset, glyph, SERENITY.white)}
  </svg>`;
}

/* ──────────────────────── Cluster pins ─────────────────────────────────── */

export type ClusterSize = 'small' | 'medium' | 'large' | 'mega';

export function clusterSizeFor(count: number): ClusterSize {
  if (count >= 100) return 'mega';
  if (count >= 50) return 'large';
  if (count >= 10) return 'medium';
  return 'small';
}

/**
 * Per-bucket dimension ranges. The cluster grows linearly inside its bucket
 * (small: 2-9 alerts → r 22-32, medium: 10-49 → r 32-48, …) so the radius
 * scales with density both within and across buckets.
 *
 * `box` is the SVG canvas / anchor side; it always equals `2 * (rMax + halo)`.
 */
const CLUSTER_RANGES: Record<ClusterSize, {
  countMin: number; countMax: number;
  rMin: number; rMax: number;
  fontMin: number; fontMax: number;
  box: number;
}> = {
  small:  { countMin: 2,   countMax: 9,    rMin: 22, rMax: 32, fontMin: 14, fontMax: 16, box: 80  },
  medium: { countMin: 10,  countMax: 49,   rMin: 32, rMax: 48, fontMin: 16, fontMax: 20, box: 112 },
  large:  { countMin: 50,  countMax: 99,   rMin: 48, rMax: 60, fontMin: 20, fontMax: 22, box: 144 },
  mega:   { countMin: 100, countMax: 1000, rMin: 60, rMax: 78, fontMin: 22, fontMax: 28, box: 184 },
};

function interp(c: number, range: typeof CLUSTER_RANGES[ClusterSize]) {
  const { countMin, countMax, rMin, rMax, fontMin, fontMax } = range;
  // Logarithmic ramp inside the bucket so the marker doesn't blow up linearly with count.
  const span = Math.log(countMax + 1) - Math.log(countMin);
  const t = span <= 0 ? 0 : Math.min(1, Math.max(0, (Math.log(c + 1) - Math.log(countMin)) / span));
  return {
    r: rMin + (rMax - rMin) * t,
    font: fontMin + (fontMax - fontMin) * t,
  };
}

export function clusterBoxFor(count: number): number {
  return CLUSTER_RANGES[clusterSizeFor(count)].box;
}

export function buildClusterPinSvg(count: number): string {
  const size = clusterSizeFor(count);
  const range = CLUSTER_RANGES[size];
  const { box } = range;
  const { r, font } = interp(count, range);
  const cx = box / 2;
  const cy = box / 2;
  const display =
    count >= 1000 ? `${Math.floor(count / 100) * 100}+`
    : count >= 200 ? '200+'
    : count >= 100 ? `${Math.floor(count / 50) * 50}+`
    : String(count);

  // Glow scales with the disk so the halo always extends past the rim.
  let glow = '';
  let blurStd = 5;
  if (size === 'medium' || size === 'large') {
    blurStd = Math.round(r * 0.18);
    glow = `<circle cx="${cx}" cy="${cy}" r="${r + r * 0.22}" fill="${SERENITY.mint}" opacity="0.32" filter="url(#blur-cluster)"/>`;
  } else if (size === 'mega') {
    blurStd = Math.round(r * 0.22);
    glow = `<circle cx="${cx}" cy="${cy}" r="${r + r * 0.28}" fill="${SERENITY.coral}" opacity="0.42" filter="url(#blur-cluster)"/>`;
  }

  // Mint border for large (subtle ring inside the rim)
  const ringStroke = size === 'large'
    ? `stroke="${SERENITY.mint}" stroke-opacity="0.6" stroke-width="1.5"`
    : '';

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${box}" height="${box}" viewBox="0 0 ${box} ${box}">
    <defs>
      <filter id="blur-cluster" x="-50%" y="-50%" width="200%" height="200%">
        <feGaussianBlur stdDeviation="${blurStd}"/>
      </filter>
    </defs>
    ${glow}
    <circle cx="${cx}" cy="${cy}" r="${r}" fill="${SERENITY.navy}" ${ringStroke}/>
    <text x="${cx}" y="${cy}" text-anchor="middle" dominant-baseline="central" font-family="Inter, system-ui, -apple-system, sans-serif" font-size="${font.toFixed(1)}" font-weight="500" fill="${SERENITY.white}">${display}</text>
  </svg>`;
}

/* ──────────────────────── Convenience: Google Maps icon objects ─────────── */

/**
 * Returns a `google.maps.Icon`-shaped object (without invoking the google
 * global — pass `g = window.google.maps` to materialise the Size/Point).
 */
export function gmapsAlertIcon(g: typeof google.maps, opts: AlertPinOptions) {
  const svg = buildAlertPinSvg(opts);
  return {
    url: dataUri(svg),
    scaledSize: new g.Size(64, 84),
    anchor: new g.Point(32, 80),
  };
}

export function gmapsClusterIcon(g: typeof google.maps, count: number) {
  const box = clusterBoxFor(count);
  const svg = buildClusterPinSvg(count);
  return {
    url: dataUri(svg),
    scaledSize: new g.Size(box, box),
    anchor: new g.Point(box / 2, box / 2),
  };
}

export function gmapsUserPositionIcon(g: typeof google.maps) {
  return {
    url: dataUri(buildUserPositionSvg()),
    scaledSize: new g.Size(56, 56),
    anchor: new g.Point(28, 28),
  };
}

export function gmapsFamilyIcon(g: typeof google.maps) {
  return {
    url: dataUri(buildFamilyPinSvg()),
    scaledSize: new g.Size(64, 64),
    anchor: new g.Point(32, 32),
  };
}

export function gmapsChildIcon(g: typeof google.maps) {
  return {
    url: dataUri(buildChildPinSvg()),
    scaledSize: new g.Size(64, 64),
    anchor: new g.Point(32, 32),
  };
}

export function gmapsGroupIcon(g: typeof google.maps, count: number, extra = 1) {
  return {
    url: dataUri(buildGroupPinSvg(count, extra)),
    scaledSize: new g.Size(64, 64),
    anchor: new g.Point(32, 32),
  };
}

export function gmapsSosIcon(g: typeof google.maps) {
  return {
    url: dataUri(buildSosPinSvg()),
    scaledSize: new g.Size(80, 80),
    anchor: new g.Point(40, 40),
  };
}
