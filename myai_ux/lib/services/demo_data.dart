import 'dart:math';
import '../main.dart';

class DemoData {
  static final Random _random = Random(42);
  
  // Rich, interconnected demo dataset
  static List<DataItem> get richDemoData => [
    
    // ============================================================================
    // VISA/IMMIGRATION CLUSTER - Shows connected information
    // ============================================================================
    DataItem(
      id: 'visa_approval_email',
      title: 'Visa Extension Approved - USCIS Case Update',
      content: 'Dear Applicant, Your OPT extension application (Receipt #MSC2310312345) has been approved. Your new employment authorization is valid until December 15, 2025. Please expect your new EAD card within 10-14 business days. Status: APPROVED. Next steps: Update employer HR department and schedule biometrics appointment if required.',
      type: 'email',
      constellation: 'personal',
      createdAt: DateTime(2025, 8, 15, 14, 30),
      path: '~/Mail/USCIS/visa_approval_08_15_2025.eml',
      relevance: 0.95,
    ),
    
    DataItem(
      id: 'embassy_appointment',
      title: 'US Embassy Appointment Confirmation',
      content: 'Appointment confirmed for biometrics and interview. Date: August 28, 2025 at 10:00 AM. Location: US Embassy, 123 Embassy Row. Required documents: Passport, I-94, employment letter, bank statements. Case number: MSC2310312345. Please arrive 15 minutes early.',
      type: 'file',
      constellation: 'personal', 
      createdAt: DateTime(2025, 8, 20, 9, 15),
      path: '~/Documents/Immigration/embassy_appointment_08_28_2025.pdf',
      relevance: 0.92,
    ),
    
    DataItem(
      id: 'visa_bank_statement',
      title: 'Bank Statement - August 2025 - Immigration Supporting Document',
      content: 'Chase Bank Statement. Account ending in 7890. Opening balance: \$15,847.32. Salary deposits: \$8,500 (Aug 1), \$8,500 (Aug 15). Current balance: \$32,891.45. Statement period: August 1-31, 2025. Used for visa documentation and USCIS financial support evidence.',
      type: 'file',
      constellation: 'personal',
      createdAt: DateTime(2025, 8, 31, 23, 59),
      path: '~/Documents/Banking/chase_statement_aug_2025_visa_docs.pdf',
      relevance: 0.88,
    ),
    
    DataItem(
      id: 'passport_photo',
      title: 'passport_scan_2025.jpg',
      content: 'Scanned copy of US passport. Page with photo and personal information. Valid until 2030. Used for visa applications and government documents. High-resolution scan suitable for official submissions.',
      type: 'image',
      constellation: 'personal',
      createdAt: DateTime(2025, 8, 10, 16, 45),
      path: '~/Documents/Immigration/passport_scan_2025.jpg',
      relevance: 0.85,
    ),

    // ============================================================================
    // KAIROZ PROJECT CLUSTER - Shows work/project connections
    // ============================================================================
    DataItem(
      id: 'kairoz_pitch_deck',
      title: 'Kairoz_Pitch_Deck_v3_Final.pptx',
      content: 'Kairoz AGI Platform - Series A Pitch Deck. 23 slides covering: Market opportunity (\$127B AI market), Product demo (MyAI personal AGI), Team (3 co-founders), Traction (10k beta users), Fundraising (\$5M Series A). Investor meeting scheduled November 1st, 2025. Confidential - NDA required.',
      type: 'file',
      constellation: 'kairoz',
      createdAt: DateTime(2025, 10, 15, 11, 20),
      path: '~/Documents/Kairoz/Fundraising/Kairoz_Pitch_Deck_v3_Final.pptx',
      relevance: 0.98,
    ),
    
    DataItem(
      id: 'investor_email_thread',
      title: 'Re: Kairoz Series A - Investor Interest from Andreessen Horowitz',
      content: 'Hi team, Great news! Marc from a16z wants to schedule a follow-up meeting after seeing our MyAI demo. They\'re particularly interested in our privacy-first approach and on-device processing. Next steps: 1) Send updated pitch deck with latest metrics 2) Prepare 30-min product demo 3) Schedule meeting for Nov 5th. This could be our lead investor! -Sarah',
      type: 'email',
      constellation: 'kairoz',
      createdAt: DateTime(2025, 10, 20, 15, 45),
      path: '~/Mail/Kairoz/investor_thread_a16z_oct_2025.eml',
      relevance: 0.96,
    ),
    
    DataItem(
      id: 'technical_architecture',
      title: 'MyAI_Technical_Architecture_v2.md',
      content: 'MyAI Technical Architecture Overview\n\n## Core Components\n- Rust backend with hybrid search (BM25 + HNSW + reranking)\n- Flutter desktop UI with cosmic visualization\n- Local-only processing (no cloud dependency)\n- ONNX models for embeddings and reranking\n\n## Performance Targets\n- <300ms query latency\n- Support for 1M+ documents\n- Real-time indexing\n- Cross-platform (Windows, macOS, Linux)\n\n## Privacy Features\n- Zero data transmission\n- Local SQLite with optional encryption\n- No telemetry or analytics',
      type: 'file',
      constellation: 'kairoz',
      createdAt: DateTime(2025, 10, 10, 14, 30),
      path: '~/Documents/Kairoz/Technical/MyAI_Technical_Architecture_v2.md',
      relevance: 0.94,
    ),
    
    DataItem(
      id: 'team_meeting_photo',
      title: 'kairoz_team_brainstorm_oct_2025.jpg',
      content: 'Kairoz team brainstorming session photo. Whiteboard shows MyAI roadmap, user acquisition funnel, and technical milestones. Team members: Alex (CTO), Sarah (CEO), Mike (CPO) discussing Q4 2025 launch strategy. Office location: San Francisco. Date: October 12, 2025.',
      type: 'image',
      constellation: 'kairoz',
      createdAt: DateTime(2025, 10, 12, 16, 30),
      path: '~/Pictures/Work/kairoz_team_brainstorm_oct_2025.jpg',
      relevance: 0.91,
    ),

    // ============================================================================
    // PERSONAL LIFE CLUSTER - Family, finances, daily life
    // ============================================================================
    DataItem(
      id: 'son_school_schedule',
      title: 'James_School_Schedule_Fall_2025.pdf',
      content: 'Lincoln Elementary - Fall 2025 Schedule for James Wilson (Grade 4). Monday-Friday: Math 9:00-9:45, Science 10:00-10:45, Reading 11:00-11:45, Lunch 12:00-12:30, Art 1:00-1:45, PE 2:00-2:45. Teacher: Mrs. Rodriguez. Parent-teacher conference: Nov 15, 2025. School starts Aug 26, 2025.',
      type: 'file',
      constellation: 'personal',
      createdAt: DateTime(2025, 8, 20, 8, 30),
      path: '~/Documents/Family/School/James_School_Schedule_Fall_2025.pdf',
      relevance: 0.89,
    ),
    
    DataItem(
      id: 'family_budget_2025',
      title: 'Family_Budget_2025_Detailed.xlsx',
      content: 'Complete family budget spreadsheet for 2025. Income: Kairoz salary \$165k/year, consulting \$25k. Expenses: Mortgage \$3,200/month, groceries \$800/month, childcare \$1,500/month, car payment \$450/month. Savings goal: \$40k for house down payment. Tech subscriptions: Cursor Pro \$20/month, GitHub Pro \$4/month, AWS \$200/month.',
      type: 'file',
      constellation: 'personal',
      createdAt: DateTime(2025, 1, 1, 10, 0),
      path: '~/Documents/Finances/Family_Budget_2025_Detailed.xlsx',
      relevance: 0.93,
    ),
    
    DataItem(
      id: 'vacation_maldives',
      title: 'maldives_sunset_august_2025.jpg',
      content: 'Beautiful sunset photo from family vacation in Maldives. Overwater bungalow at Conrad Maldives resort. Taken during anniversary trip with wife. Crystal clear turquoise water, palm trees, golden hour lighting. Camera: iPhone 15 Pro. Date: August 5, 2025. Best vacation ever - need to book again next year!',
      type: 'image',
      constellation: 'personal',
      createdAt: DateTime(2025, 8, 5, 18, 45),
      path: '~/Pictures/Vacations/maldives_sunset_august_2025.jpg',
      relevance: 0.87,
    ),

    // ============================================================================
    // HEALTH & FITNESS CLUSTER
    // ============================================================================
    DataItem(
      id: 'gym_membership',
      title: 'Equinox Gym Membership Receipt - Annual Plan',
      content: 'Equinox Fitness membership renewed for 2025. Annual plan: \$2,400 (\$200/month). Includes: All club access, group fitness classes, personal training sessions. Member since 2020. Auto-renewal date: January 1, 2026. Favorite classes: CrossFit (Mon/Wed/Fri 7am), Yoga (Tue/Thu 6pm).',
      type: 'file',
      constellation: 'personal',
      createdAt: DateTime(2025, 1, 3, 14, 20),
      path: '~/Documents/Health/equinox_membership_2025.pdf',
      relevance: 0.82,
    ),
    
    DataItem(
      id: 'health_checkup',
      title: 'Annual Health Checkup Results - Dr. Martinez',
      content: 'Annual physical exam results. Overall health: Excellent. Blood pressure: 118/75 (normal), Cholesterol: 180 mg/dL (good), BMI: 23.1 (healthy). Recommendations: Continue current exercise routine, maintain Mediterranean diet, schedule eye exam. Next checkup: August 2026. All vaccination up to date.',
      type: 'file',
      constellation: 'personal',
      createdAt: DateTime(2025, 8, 12, 11, 15),
      path: '~/Documents/Health/annual_checkup_aug_2025.pdf',
      relevance: 0.84,
    ),

    // ============================================================================
    // RECENT MESSAGES/COMMUNICATIONS
    // ============================================================================
    DataItem(
      id: 'demo_link_message',
      title: 'MyAI Demo Link - Share with Investors',
      content: 'Here\'s the latest MyAI demo link for the investor meeting: https://demo.myai.dev/preview Password: nexus2025 Features to highlight: 1) Instant search across 50k+ documents 2) Cosmic UI visualization 3) Privacy-first architecture 4) Cross-platform desktop app. Demo data includes realistic personal/work scenarios. -Alex',
      type: 'message',
      constellation: 'kairoz',
      createdAt: DateTime(2025, 10, 22, 9, 30),
      path: '~/Messages/Slack/myai_demo_link_oct_2025.txt',
      relevance: 0.99,
    ),
    
    DataItem(
      id: 'mortgage_refinance',
      title: 'Mortgage Refinance Opportunity - Save \$400/month',
      content: 'Hi! Rates have dropped to 5.8%. Based on your current mortgage (\$580k remaining), you could refinance and save \$400/month. New payment would be \$2,800 vs current \$3,200. Estimated closing costs: \$8,500. Break-even: 21 months. Let me know if you want to move forward! -Jennifer, Wells Fargo',
      type: 'email',
      constellation: 'personal',
      createdAt: DateTime(2025, 10, 25, 13, 45),
      path: '~/Mail/Finance/mortgage_refinance_oct_2025.eml',
      relevance: 0.90,
    ),

    // ============================================================================
    // TECH/DEVELOPMENT CLUSTER
    // ============================================================================
    DataItem(
      id: 'myai_development_notes',
      title: 'MyAI_Development_Notes_October_2025.md',
      content: '# MyAI Development Progress - October 2025\n\n## Completed\n- ✅ Rust backend with sub-300ms queries\n- ✅ Flutter desktop UI with cosmic visualization\n- ✅ ONNX model integration (MiniLM + BGE reranker)\n- ✅ Hybrid search pipeline (BM25 + HNSW + reranking)\n\n## In Progress\n- 🔄 Windows installer package\n- 🔄 Auto-model download system\n- 🔄 System tray integration\n\n## Next Up\n- 📋 MacOS build and notarization\n- 📋 Linux AppImage packaging\n- 📋 Beta user onboarding flow',
      type: 'file',
      constellation: 'kairoz',
      createdAt: DateTime(2025, 10, 28, 22, 15),
      path: '~/Documents/Kairoz/Development/MyAI_Development_Notes_October_2025.md',
      relevance: 0.97,
    ),

    // ============================================================================
    // RECENT PURCHASES & RECEIPTS
    // ============================================================================
    DataItem(
      id: 'laptop_purchase',
      title: 'MacBook Pro 16" M3 Max - Development Machine Receipt',
      content: 'Apple Store receipt. MacBook Pro 16" with M3 Max chip, 64GB RAM, 2TB SSD. Price: \$4,399. Purchased for MyAI development - need powerful machine for ML model testing. AppleCare+ included. Order #W123456789. Delivery: October 15, 2025. Perfect for running multiple ONNX models simultaneously.',
      type: 'file',
      constellation: 'kairoz',
      createdAt: DateTime(2025, 10, 10, 15, 30),
      path: '~/Documents/Receipts/macbook_pro_m3_max_oct_2025.pdf',
      relevance: 0.86,
    ),

    // Add more interconnected data for rich demo experience...
  ];

  // Curated demo search queries that show off the AI
  static List<DemoQuery> get mindBlowingQueries => [
    DemoQuery(
      query: 'visa',
      description: 'Immigration & Legal Documents',
      expectedResults: 4,
      highlightFeature: 'Connected Information Discovery',
      demoScript: 'Watch how MyAI instantly finds all visa-related documents, emails, photos, and bank statements - showing the full story of your immigration journey.',
    ),
    
    DemoQuery(
      query: 'Kairoz pitch deck',
      description: 'Business & Work Projects', 
      expectedResults: 5,
      highlightFeature: 'Cross-Format Intelligence',
      demoScript: 'See how MyAI connects your pitch deck with related emails, technical docs, team photos, and investor communications - your entire project in context.',
    ),
    
    DemoQuery(
      query: 'budget money mortgage',
      description: 'Personal Finance Intelligence',
      expectedResults: 4,
      highlightFeature: 'Smart Context Understanding',
      demoScript: 'MyAI understands financial context - linking budgets, bank statements, mortgage info, and refinancing opportunities across different document types.',
    ),
    
    DemoQuery(
      query: 'James school',
      description: 'Family & Personal Life',
      expectedResults: 2,
      highlightFeature: 'Family Information Hub',
      demoScript: 'Find everything about your family life instantly - school schedules, health records, vacation photos, and important dates.',
    ),
    
    DemoQuery(
      query: 'demo link investor',
      description: 'Recent Communications',
      expectedResults: 2,
      highlightFeature: 'Time-Aware Search',
      demoScript: 'MyAI finds the most recent and relevant communications, understanding urgency and importance.',
    ),
  ];

  // Demo scenarios for the "wow factor"
  static List<DemoScenario> get impressiveScenarios => [
    DemoScenario(
      title: '🕰️ "Time Machine" Search',
      description: 'Ask about what you were doing at any point in time',
      sampleQuery: 'What was I working on last month?',
      impact: 'Shows how MyAI becomes your personal memory assistant',
    ),
    
    DemoScenario(
      title: '🧠 "Mind Reader" Intelligence', 
      description: 'MyAI understands context and intent, not just keywords',
      sampleQuery: 'budget',
      impact: 'Demonstrates true AI understanding vs simple keyword matching',
    ),
    
    DemoScenario(
      title: '🕸️ "Connection Web" Discovery',
      description: 'Click any document to see related information across all your data',
      sampleQuery: 'Click visa document → See connected emails, photos, bank statements',
      impact: 'Shows how MyAI maps relationships between your information',
    ),
    
    DemoScenario(
      title: '⚡ "Instant Everything" Speed',
      description: 'Sub-300ms responses across thousands of documents',
      sampleQuery: 'Real-time search-as-you-type',
      impact: 'Proves this isn\'t just a prototype - it\'s production-ready',
    ),
    
    DemoScenario(
      title: '🔒 "Privacy First" Promise',
      description: 'Everything runs locally - no data ever leaves your device',
      sampleQuery: 'Show network monitor during search',
      impact: 'Addresses biggest concern about AI - your data stays yours',
    ),
  ];
}

class DemoQuery {
  final String query;
  final String description;
  final int expectedResults;
  final String highlightFeature;
  final String demoScript;
  
  DemoQuery({
    required this.query,
    required this.description,
    required this.expectedResults,
    required this.highlightFeature,
    required this.demoScript,
  });
}

class DemoScenario {
  final String title;
  final String description;
  final String sampleQuery;
  final String impact;
  
  DemoScenario({
    required this.title,
    required this.description,
    required this.sampleQuery,
    required this.impact,
  });
}