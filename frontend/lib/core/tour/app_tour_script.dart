import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'spotlight_tour.dart';

/// The guided tour, page by page. Each chapter opens with a card, then lights up the
/// page's important controls one at a time. A stop whose element is not on screen in
/// the current layout (an editorial-only word, a wide-screen card) is skipped.
abstract final class AppTourScript {
  static const _welcome = 'Welcome';
  static const _frame = 'Getting around';
  static const _home = 'Home';
  static const _notes = 'Notes';
  static const _tasks = 'Tasks';
  static const _planner = 'Planner';
  static const _money = 'Money';
  static const _habits = 'Habits';
  static const _journal = 'Journal';
  static const _settings = 'Settings';
  static const _done = 'Done';

  static const stops = <TourStop>[
    TourStop.chapter(
      chapter: _welcome,
      icon: LucideIcons.compass,
      module: 0,
      title: 'Welcome to NOTtEodo',
      body: 'This tour visits each page and lights up its buttons one at a time, with a note on what each one does '
          'and how to use it. Tap Next or the dimmed area to move on, swipe to go back and forth, and leave whenever '
          'you like with End tour.',
    ),

    // --- The frame every page shares ------------------------------------------
    TourStop.chapter(
      chapter: _frame,
      icon: LucideIcons.layoutDashboard,
      module: 0,
      title: 'Getting around',
      body: 'Every page sits in the same frame: a bar along the top and a dock along the bottom. These are the '
          'controls you will use everywhere.',
    ),
    TourStop.spot(
      chapter: _frame,
      icon: LucideIcons.layoutDashboard,
      module: 0,
      target: 'shell.menu',
      title: 'Menu',
      body: 'Opens the side menu with every section, including the ones that are not in the dock: Wardrobe, Travel, '
          'Moodboard, Shopping, the Vault, the Bin and Settings. This tour lives there too.',
      editorialBody: 'Opens the full list of sections, plus light and dark pages, feedback and sign-in. Use it for '
          'anything that is not in the dock.',
    ),
    TourStop.spot(
      chapter: _frame,
      icon: LucideIcons.layoutDashboard,
      module: 0,
      target: 'shell.ask',
      title: 'Ask Nodo',
      body: 'The spark opens Nodo, your assistant. Ask about anything you have saved, or have it summarise, plan or '
          'rewrite for you. It knows which page you are on.',
    ),
    TourStop.spot(
      chapter: _frame,
      icon: LucideIcons.layoutDashboard,
      module: 0,
      target: 'shell.voice',
      title: 'Voice memo',
      body: 'Speak instead of typing. Your recording is transcribed and saved, ready to turn into a note or a task.',
    ),
    TourStop.spot(
      chapter: _frame,
      icon: LucideIcons.layoutDashboard,
      module: 0,
      target: 'shell.search',
      title: 'Search everything',
      body: 'Finds notes, tasks, events, expenses and more by any word, and opens each result where it lives. With a '
          'keyboard, Ctrl + K opens it from anywhere.',
    ),
    TourStop.spot(
      chapter: _frame,
      icon: LucideIcons.layoutDashboard,
      module: 0,
      target: 'shell.view',
      title: 'Cards or Editorial',
      body: 'Changes how the whole app looks. The icon shows the view you will switch to: lines of type under a '
          'headline is Editorial, with words on paper and no boxes. Your data is the same in both.',
      editorialBody: 'Changes how the whole app looks. The icon shows the view you will switch to: stacked cards is '
          'the Cards view, with every item on its own card. Your data is the same in both.',
    ),
    TourStop.spot(
      chapter: _frame,
      icon: LucideIcons.layoutDashboard,
      module: 0,
      target: 'shell.theme',
      title: 'Light and dark',
      body: 'Switches between light and dark. The icon shows where you will go: a moon for dark, a sun for light.',
    ),
    TourStop.spot(
      chapter: _frame,
      icon: LucideIcons.layoutDashboard,
      module: 0,
      target: 'shell.dock.space',
      title: 'Work and Life',
      body: 'The dock carries two sets of pages. Tap here to swap between Work (Home, Notes, Tasks, Planner) and Life '
          '(Expenses, Travel, Journal, Moodboard, Habits).',
    ),
    TourStop.spot(
      chapter: _frame,
      icon: LucideIcons.layoutDashboard,
      module: 0,
      target: 'shell.dock.tabs',
      title: 'Your pages',
      body: 'Tap a tab to open that page. The glowing highlight shows where you are, and the small numbers count your '
          'open tasks and your notes.',
      editorialBody: 'Tap a word to open that page; the one you are on is underlined. Choose which four pages sit here '
          'in Settings, Look & feel.',
    ),
    TourStop.spot(
      chapter: _frame,
      icon: LucideIcons.layoutDashboard,
      module: 0,
      target: 'shell.dock.more',
      title: 'More',
      body: 'Opens every other page. When you are on a page that is not in the dock, its name shows here instead.',
    ),
    TourStop.spot(
      chapter: _frame,
      icon: LucideIcons.layoutDashboard,
      module: 0,
      target: 'shell.dock.create',
      title: 'Create anything',
      body: 'Tap to open the create dial and pick a note, task, event, expense and more. Press and hold to talk to '
          'Nodo instead.',
      editorialBody: 'Tap + to add something new for the page you are on. Press and hold for quick capture, which '
          'turns a plain sentence like "Lunch ₹300 tomorrow 1pm" into the right kind of entry.',
    ),
    TourStop.spot(
      chapter: _frame,
      icon: LucideIcons.layoutDashboard,
      module: 0,
      target: 'shell.dock.collapse',
      title: 'Tuck the dock away',
      body: 'Shrinks the dock into a small island so the page has more room. Tap the island to bring it back. The dock '
          'also slips away as you scroll down and returns when you scroll up.',
    ),
    TourStop.spot(
      chapter: _frame,
      icon: LucideIcons.layoutDashboard,
      module: 0,
      target: 'shell.nodo',
      title: 'Nodo, your companion',
      body: 'This orb is Nodo. It moves around the screen and offers a timely suggestion now and then. Tap it to chat, '
          'or drag it somewhere out of your way.',
    ),
    TourStop.spot(
      chapter: _frame,
      icon: LucideIcons.layoutDashboard,
      module: 0,
      target: 'shell.voiceDial',
      title: 'Voice capture',
      body: 'Tap the microphone to speak a note or a task. Like Nodo, you can drag it anywhere on the screen.',
    ),

    // --- Home ------------------------------------------------------------------
    TourStop.chapter(
      chapter: _home,
      icon: LucideIcons.home,
      module: 0,
      title: 'Home, your day at a glance',
      body: 'Home brings today together: your streak, what is due, your spending and your latest note, so the day '
          'starts in one place.',
    ),
    TourStop.spot(
      chapter: _home,
      icon: LucideIcons.home,
      module: 0,
      target: 'home.goal',
      title: 'Streak and daily goal',
      body: 'The ring fills as you finish today\'s tasks and habits, and the number is your streak: days in a row you '
          'have shown up. Tap it to see today\'s streak.',
    ),
    TourStop.spot(
      chapter: _home,
      icon: LucideIcons.home,
      module: 0,
      target: 'home.quick',
      title: 'Quick actions',
      gesture: TourGesture.swipe,
      body: 'Capture writes anything down in plain words. Check-in seals today\'s progress. Your week is a weekly '
          'summary, Evening review closes the day, and Zen mode hides all but the essentials. Swipe the row to see '
          'them all.',
    ),
    TourStop.spot(
      chapter: _home,
      icon: LucideIcons.home,
      module: 0,
      target: 'home.briefing',
      title: 'Daily briefing',
      gesture: TourGesture.read,
      body: 'A short summary of your day from Nodo: what is due, what is planned and what needs attention. You can '
          'hide it in Settings, Display & layout.',
    ),
    TourStop.spot(
      chapter: _home,
      icon: LucideIcons.home,
      module: 0,
      target: 'home.today',
      title: 'Today\'s tasks',
      body: 'Tick a task to complete it. The filters show morning, afternoon or evening tasks, and Add task puts a new '
          'one here straight away.',
      editorialTitle: 'Agenda',
      editorialBody: 'Today\'s events with their times, then the tasks due today. Tap the circle to tick a task off, '
          'or tap a line to open it.',
    ),
    TourStop.spot(
      chapter: _home,
      icon: LucideIcons.home,
      module: 0,
      target: 'home.money',
      title: 'Spending this month',
      body: 'What you have spent against your monthly budget. Tap the card to log a new expense.',
    ),
    TourStop.spot(
      chapter: _home,
      icon: LucideIcons.home,
      module: 0,
      target: 'home.notes',
      title: 'Latest note and habits',
      body: 'Your most recent note, ready to pick up where you left off, beside today\'s habits. New note and Ask Nodo '
          'are right on the card.',
    ),
    TourStop.spot(
      chapter: _home,
      icon: LucideIcons.home,
      module: 0,
      target: 'home.tools',
      title: 'Tools',
      body: 'Every quick action as a word: the focus timer, a voice note, Nodo, quick capture, a new task, expense or '
          'note, and the daily briefing.',
    ),
    TourStop.spot(
      chapter: _home,
      icon: LucideIcons.home,
      module: 0,
      target: 'home.zen',
      title: 'Evening review',
      body: 'At the end of the day, look back on what you did, carry over what is left and keep your streak alive.',
    ),

    // --- Notes -----------------------------------------------------------------
    TourStop.chapter(
      chapter: _notes,
      icon: LucideIcons.fileText,
      module: 1,
      title: 'Notes that stay organised',
      body: 'Write with headings, lists and checkboxes, group notes into spaces, and find any of them again in seconds.',
    ),
    TourStop.spot(
      chapter: _notes,
      icon: LucideIcons.fileText,
      module: 1,
      target: 'page.primary',
      title: 'New note',
      body: 'Starts a fresh note. Use the formatting bar for bold, lists and checkboxes, and add #tags to group '
          'related notes. Pinned notes stay at the top.',
      editorialTitle: 'Write',
    ),
    TourStop.spot(
      chapter: _notes,
      icon: LucideIcons.fileText,
      module: 1,
      target: 'notes.tools',
      title: 'Note tools',
      gesture: TourGesture.swipe,
      body: 'From the left: select several notes at once, import a PDF or text file, write by hand, view two notes '
          'side by side, change the note font, and see your notes as a mind map. Weekly summary sums up the week.',
    ),
    TourStop.spot(
      chapter: _notes,
      icon: LucideIcons.fileText,
      module: 1,
      target: 'notes.spaces',
      title: 'Spaces',
      body: 'Notes live in spaces such as Work or Personal. Tap a space to see only its notes. Smart groups lets Nodo '
          'cluster related notes for you.',
    ),

    // --- Tasks -----------------------------------------------------------------
    TourStop.chapter(
      chapter: _tasks,
      icon: LucideIcons.checkSquare,
      module: 2,
      title: 'Tasks and reminders',
      body: 'Keep a list of what to do, give each task a date and a reminder, and tick them off as you go.',
    ),
    TourStop.spot(
      chapter: _tasks,
      icon: LucideIcons.checkSquare,
      module: 2,
      target: 'page.primary',
      title: 'Add a task',
      body: 'Add a to-do with a due date, a time of day and a reminder. Tasks with a date also appear in the Planner.',
      editorialTitle: 'New task',
    ),
    TourStop.spot(
      chapter: _tasks,
      icon: LucideIcons.checkSquare,
      module: 2,
      target: 'tasks.checkin',
      title: 'Check in',
      body: 'Seal the day\'s progress with a quick check-in. It counts towards your streak.',
    ),
    TourStop.spot(
      chapter: _tasks,
      icon: LucideIcons.checkSquare,
      module: 2,
      target: 'tasks.progress',
      title: 'Progress',
      gesture: TourGesture.read,
      body: 'How many of your tasks are done, as a figure and a bar that fills as you go.',
    ),
    TourStop.spot(
      chapter: _tasks,
      icon: LucideIcons.checkSquare,
      module: 2,
      target: 'tasks.filters',
      title: 'Filters and the list',
      gesture: TourGesture.swipe,
      body: 'Show today\'s, upcoming, overdue or completed tasks, or just the morning, afternoon or evening. In the '
          'list below, tap the circle to finish a task, swipe it away to delete it, or use ⋯ to reschedule it or set a '
          'reminder.',
    ),

    // --- Planner ---------------------------------------------------------------
    TourStop.chapter(
      chapter: _planner,
      icon: LucideIcons.calendar,
      module: 3,
      title: 'Plan the week ahead',
      body: 'Your events and dated tasks laid out on a calendar, so you can see a busy day coming.',
    ),
    TourStop.spot(
      chapter: _planner,
      icon: LucideIcons.calendar,
      module: 3,
      target: 'planner.week',
      title: 'Your week',
      body: 'Tap a day to see what is on. The filled disc marks the chosen day and a dot marks busy days. The arrows '
          'move a week at a time, and Today jumps back.',
    ),
    TourStop.spot(
      chapter: _planner,
      icon: LucideIcons.calendar,
      module: 3,
      target: 'page.primary',
      title: 'New event',
      body: 'Adds an event to the chosen day. Tap an hour in the day first and the event starts then.',
    ),
    TourStop.spot(
      chapter: _planner,
      icon: LucideIcons.calendar,
      module: 3,
      target: 'planner.files',
      title: 'Calendar files',
      body: 'Import events from Google, Apple or Outlook as an .ics file, or export yours to use elsewhere.',
    ),

    // --- Money -----------------------------------------------------------------
    TourStop.chapter(
      chapter: _money,
      icon: LucideIcons.wallet,
      module: 5,
      title: 'Spending and budgets',
      body: 'Log what you spend, set a monthly budget, keep an eye on subscriptions and split bills without the maths.',
    ),
    TourStop.spot(
      chapter: _money,
      icon: LucideIcons.wallet,
      module: 5,
      target: 'page.primary',
      title: 'Add an expense',
      body: 'Log the amount, a category and a note. Logging right after you pay takes five seconds.',
      editorialTitle: 'Add',
    ),
    TourStop.spot(
      chapter: _money,
      icon: LucideIcons.wallet,
      module: 5,
      target: 'expenses.split',
      title: 'Split a bill',
      body: 'Share a bill between friends, add a tip, and keep track of who owes whom.',
    ),
    TourStop.spot(
      chapter: _money,
      icon: LucideIcons.wallet,
      module: 5,
      target: 'expenses.export',
      title: 'Export',
      body: 'Download a report of your spending whenever you need a record.',
    ),
    TourStop.spot(
      chapter: _money,
      icon: LucideIcons.wallet,
      module: 5,
      target: 'expenses.month',
      title: 'This month',
      gesture: TourGesture.read,
      body: 'Your spending against the monthly budget; the bar turns red if you go over. Edit changes the budget. '
          'Below are what you can spend per day until the month ends, and your subscriptions.',
    ),
    TourStop.spot(
      chapter: _money,
      icon: LucideIcons.wallet,
      module: 5,
      target: 'expenses.envelopes',
      title: 'Budget envelopes',
      body: 'Split your budget into envelopes such as Food or Travel and see what is left in each.',
    ),

    // --- Habits ----------------------------------------------------------------
    TourStop.chapter(
      chapter: _habits,
      icon: LucideIcons.target,
      module: 9,
      title: 'Habits and streaks',
      body: 'Build routines one day at a time. Each day you show up adds to your streak.',
    ),
    TourStop.spot(
      chapter: _habits,
      icon: LucideIcons.target,
      module: 9,
      target: 'page.primary',
      title: 'New habit',
      body: 'Add something you want to do regularly and choose the days it is due. Start with one small habit.',
    ),
    TourStop.spot(
      chapter: _habits,
      icon: LucideIcons.target,
      module: 9,
      target: 'habits.today',
      title: 'Today and your consistency',
      gesture: TourGesture.read,
      body: 'How many of today\'s habits are done, then a grid of recent weeks where darker squares mean more done that '
          'day. Below it, tap a habit to tick it off for today.',
    ),

    // --- Journal ---------------------------------------------------------------
    TourStop.chapter(
      chapter: _journal,
      icon: LucideIcons.bookOpen,
      module: 7,
      title: 'Your journal',
      body: 'A private place to write about your day, with a mood and even a voice recording.',
    ),
    TourStop.spot(
      chapter: _journal,
      icon: LucideIcons.bookOpen,
      module: 7,
      target: 'page.primary',
      title: 'New entry',
      body: 'Write about your day and pick a mood. Entries are set for reading, newest first.',
      editorialTitle: 'Write',
    ),
    TourStop.spot(
      chapter: _journal,
      icon: LucideIcons.bookOpen,
      module: 7,
      target: 'journal.vault',
      title: 'Vault',
      body: 'Keeps your most private entries encrypted on this device, behind a PIN only you know.',
    ),

    // --- Settings --------------------------------------------------------------
    TourStop.chapter(
      chapter: _settings,
      icon: LucideIcons.settings,
      module: 11,
      title: 'Make it yours',
      body: 'Settings is where you shape the app: how it looks, how it reminds you, and how your data is kept safe.',
    ),
    TourStop.spot(
      chapter: _settings,
      icon: LucideIcons.settings,
      module: 11,
      target: 'settings.profile',
      title: 'Your profile',
      body: 'Your name, location and streak. Tap it to change how the app greets you.',
    ),
    TourStop.spot(
      chapter: _settings,
      icon: LucideIcons.settings,
      module: 11,
      target: 'settings.personal',
      title: 'Personal',
      body: 'Look & feel sets the view, accent colour, text size and gestures. Display & layout, Sounds and '
          'Notifications fine-tune the rest.',
    ),
    TourStop.spot(
      chapter: _settings,
      icon: LucideIcons.settings,
      module: 11,
      target: 'settings.privacy',
      title: 'Privacy and data',
      body: 'Set a PIN and app lock, sign in to sync across devices, make encrypted backups, and see exactly what stays '
          'on your phone.',
    ),
    TourStop.spot(
      chapter: _settings,
      icon: LucideIcons.settings,
      module: 11,
      target: 'settings.about',
      title: 'Help and this tour',
      body: 'Replay this tour any time from Diagnostics & System Tools, and find answers in Help & Support.',
    ),

    TourStop.chapter(
      chapter: _done,
      icon: LucideIcons.partyPopper,
      module: 0,
      title: 'You are all set',
      body: 'A good first day: capture three things on your mind, pick one task to finish, start one small habit, and '
          'come back tonight for the evening review.',
    ),
  ];
}
