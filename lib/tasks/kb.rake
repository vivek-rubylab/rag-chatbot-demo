namespace :kb do
  desc "Re-embed all active knowledge entries using retrieval_text (falls back to title + body)"
  task reembed: :environment do
    unless ENV["OPENAI_API_KEY"].present?
      raise "OPENAI_API_KEY is not set. Cannot re-embed entries."
    end

    entries = KnowledgeEntry.active.order(:id)
    total   = entries.count

    if total.zero?
      puts "No active knowledge entries found. Nothing to do."
      next
    end

    puts "Re-embedding #{total} knowledge entries..."

    entries.each_with_index do |entry, i|
      entry.generate_embedding!
      puts "  [#{i + 1}/#{total}] #{entry.title}"
    rescue => e
      puts "  [#{i + 1}/#{total}] FAILED — #{entry.title}: #{e.message}"
    end

    puts "Done."
  end

  desc "Seed knowledge base with Eleven Plus Exams Tuition course and delivery content"
  task seed: :environment do
    entries = [

      # ── About & overview ──────────────────────────────────────────────────

      {
        title: "About Eleven Plus Exams Tuition",
        body: "Eleven Plus Exams Tuition was founded in 2013 by the creators of the UK's first and most respected website providing expert and impartial advice about 11+ tests. Based in Harrow, we offer in-person tuition at our centre as well as live online lessons available to students nationwide.",
        retrieval_text: <<~TEXT
          Title: About Eleven Plus Exams Tuition
          Body: Eleven Plus Exams Tuition was founded in 2013 by the creators of the UK's first and most respected website providing expert and impartial advice about 11+ tests. Based in Harrow, we offer in-person tuition at our centre as well as live online lessons available to students nationwide.
          Synonyms and related terms: eleven plus, 11+, 11 plus, tuition centre, Harrow, founded 2013, about us, who we are
          Likely questions: Who are Eleven Plus Exams Tuition? Where are you based? How long have you been running? Are you a reputable tuition provider? Do you offer lessons outside Harrow?
          Keywords: Eleven Plus Exams Tuition, Harrow, 2013, online, in-person, nationwide
        TEXT
      },

      {
        title: "What is the 11+ exam?",
        body: "The 11+ (eleven plus) is a selective entrance examination sat by children typically in Year 6, used by grammar schools and some independent schools to assess suitability for entry. It tests core subjects including English, Maths, Verbal Reasoning and Non-Verbal Reasoning. Different schools use different exam boards — the most common are GL Assessment and CEM.",
        retrieval_text: <<~TEXT
          Title: What is the 11+ exam?
          Body: The 11+ (eleven plus) is a selective entrance examination sat by children typically in Year 6, used by grammar schools and some independent schools to assess suitability for entry. It tests core subjects including English, Maths, Verbal Reasoning and Non-Verbal Reasoning. Different schools use different exam boards — the most common are GL Assessment and CEM.
          Synonyms and related terms: 11+, eleven plus, 11 plus exam, selective exam, grammar school entry, entrance test, secondary school selection
          Likely questions: What is the 11+ exam? What does the 11+ test? Which schools use the 11+? What subjects are in the 11+? When do children sit the 11+?
          Keywords: 11+, eleven plus, grammar school, independent school, English, Maths, Verbal Reasoning, Non-Verbal Reasoning, GL Assessment, CEM, Year 6
        TEXT
      },

      {
        title: "Courses available at Eleven Plus Exams Tuition",
        body: "We offer structured tuition courses for Year 3, Year 4, Year 5 and Year 6 children, as well as intensive holiday courses. Each course is available in-person at our Harrow centre or online via live interactive lessons. The Year 3 online course uses pre-recorded video tutorials. Our courses cover all major 11+ exam boards including GL Assessment, CEM and ISEB.",
        retrieval_text: <<~TEXT
          Title: Courses available at Eleven Plus Exams Tuition
          Body: We offer structured tuition courses for Year 3, Year 4, Year 5 and Year 6 children, as well as intensive holiday courses. Each course is available in-person at our Harrow centre or online via live interactive lessons. The Year 3 online course uses pre-recorded video tutorials. Our courses cover all major 11+ exam boards including GL Assessment, CEM and ISEB.
          Synonyms and related terms: 11+ courses, tuition programme, year groups, course options, eleven plus preparation, what courses do you offer
          Likely questions: What courses do you offer? Which year groups do you teach? Do you have courses for all year groups? What age do you start tuition? Do you offer both online and in-person?
          Keywords: Year 3, Year 4, Year 5, Year 6, intensive, online, in-person, GL Assessment, CEM, ISEB, Harrow
        TEXT
      },

      # ── Year 3 ────────────────────────────────────────────────────────────

      {
        title: "Year 3 Course Overview",
        body: "The Year 3 course is a 25-week programme running from January to July, with once-weekly lessons of 2 hours. It is an all-inclusive course covering English and Maths, designed to build a strong foundation for Year 4. All course materials are included. The course features detailed weekly homework tracking and detailed end-of-term reports, and gives students priority booking for the Year 4 course.",
        retrieval_text: <<~TEXT
          Title: Year 3 Course Overview
          Body: The Year 3 course is a 25-week programme running from January to July, with once-weekly lessons of 2 hours. It is an all-inclusive course covering English and Maths, designed to build a strong foundation for Year 4. All course materials are included. The course features detailed weekly homework tracking and detailed end-of-term reports, and gives students priority booking for the Year 4 course.
          Synonyms and related terms: Year 3, Y3, Yr3, year three, 11+ Year 3, eleven plus Year 3, foundation course, junior course
          Likely questions: Do you offer tuition for Year 3? When does the Year 3 course start? How long is the Year 3 course? What does the Year 3 course cover? Is there a Year 3 option?
          Keywords: Year 3, English, Maths, 25 weeks, January, July, 2 hours, homework tracking, end-of-term report, priority booking Year 4
        TEXT
      },

      {
        title: "Year 3 Subjects",
        body: "The Year 3 course covers English and Maths (excluding creative writing). It is designed to build and solidify core skills in numeracy and literacy as a foundation for the more advanced Year 4 and Year 5 content.",
        retrieval_text: <<~TEXT
          Title: Year 3 Subjects
          Body: The Year 3 course covers English and Maths (excluding creative writing). It is designed to build and solidify core skills in numeracy and literacy as a foundation for the more advanced Year 4 and Year 5 content.
          Synonyms and related terms: Year 3 subjects, Year 3 curriculum, what Year 3 covers, Year 3 English, Year 3 Maths, Year 3 topics
          Likely questions: What subjects are covered in Year 3? Does Year 3 include verbal reasoning? Is creative writing part of Year 3? What does my Year 3 child learn?
          Keywords: Year 3, English, Maths, numeracy, literacy, foundation, no verbal reasoning, no creative writing
        TEXT
      },

      {
        title: "Year 3 Online Course Format",
        body: "The Year 3 online course replicates the in-person course using pre-recorded video tutorials. Live interactive lessons are not provided for Year 3 online. The course includes over 250 topic and sub-topic videos. Students receive identical books and homework to the in-person groups, allowing all students to be monitored and assessed as one cohort. The online Year 3 course costs £1,800.",
        retrieval_text: <<~TEXT
          Title: Year 3 Online Course Format
          Body: The Year 3 online course replicates the in-person course using pre-recorded video tutorials. Live interactive lessons are not provided for Year 3 online. The course includes over 250 topic and sub-topic videos. Students receive identical books and homework to the in-person groups, allowing all students to be monitored and assessed as one cohort. The online Year 3 course costs £1,800.
          Synonyms and related terms: Year 3 online, Y3 online, Year 3 remote, Year 3 virtual, Year 3 video lessons, pre-recorded Year 3
          Likely questions: Is the Year 3 course available online? Are Year 3 lessons live? Does Year 3 online have pre-recorded videos? Can my Year 3 child learn from home? Is Year 3 online the same as in-person?
          Keywords: Year 3, online, pre-recorded, video tutorials, 250 videos, no live lessons, £1800, identical books, homework
        TEXT
      },

      {
        title: "Year 3 In-Person Course",
        body: "The Year 3 in-person course is held at our Harrow centre. It runs for 25 weeks from January to July with once-weekly 2-hour lessons. All books and materials are included. The in-person Year 3 course costs £2,400.",
        retrieval_text: <<~TEXT
          Title: Year 3 In-Person Course
          Body: The Year 3 in-person course is held at our Harrow centre. It runs for 25 weeks from January to July with once-weekly 2-hour lessons. All books and materials are included. The in-person Year 3 course costs £2,400.
          Synonyms and related terms: Year 3 in-person, Year 3 classroom, Year 3 face to face, Year 3 Harrow, attend Year 3 in person
          Likely questions: Can my Year 3 child attend in person? Where is the Year 3 class held? Is there a classroom option for Year 3? How much is the Year 3 in-person course?
          Keywords: Year 3, in-person, Harrow, 25 weeks, 2 hours, £2400, materials included
        TEXT
      },

      # ── Year 4 ────────────────────────────────────────────────────────────

      {
        title: "Year 4 Course Overview",
        body: "The Year 4 course is an all-inclusive 34-week programme running from October to July, with once-weekly lessons of 2.5 hours. It covers English, Mathematics and Verbal Reasoning, promoting and solidifying core skills in numeracy, literacy, vocabulary and reading comprehension. All books and materials are included.",
        retrieval_text: <<~TEXT
          Title: Year 4 Course Overview
          Body: The Year 4 course is an all-inclusive 34-week programme running from October to July, with once-weekly lessons of 2.5 hours. It covers English, Mathematics and Verbal Reasoning, promoting and solidifying core skills in numeracy, literacy, vocabulary and reading comprehension. All books and materials are included.
          Synonyms and related terms: Year 4, Y4, Yr4, year four, 11+ Year 4, eleven plus Year 4, Year 4 tuition
          Likely questions: Do you offer Year 4 tuition? When does Year 4 start? How long is the Year 4 course? What does Year 4 cover? How many weeks is Year 4?
          Keywords: Year 4, English, Maths, Mathematics, Verbal Reasoning, 34 weeks, October, July, 2.5 hours, all-inclusive
        TEXT
      },

      {
        title: "Year 4 Subjects",
        body: "The Year 4 course covers English, Mathematics and Verbal Reasoning. It promotes and solidifies core skills in numeracy, literacy, vocabulary and reading comprehension. Non-Verbal Reasoning is introduced in Year 5.",
        retrieval_text: <<~TEXT
          Title: Year 4 Subjects
          Body: The Year 4 course covers English, Mathematics and Verbal Reasoning. It promotes and solidifies core skills in numeracy, literacy, vocabulary and reading comprehension. Non-Verbal Reasoning is introduced in Year 5.
          Synonyms and related terms: Year 4 subjects, Year 4 curriculum, what Year 4 covers, Year 4 VR, Year 4 verbal reasoning, Year 4 English Maths
          Likely questions: What subjects are in Year 4? Does Year 4 include verbal reasoning? Is NVR taught in Year 4? What does my Year 4 child learn? Does Year 4 cover non-verbal reasoning?
          Keywords: Year 4, English, Maths, Mathematics, Verbal Reasoning, VR, reading comprehension, vocabulary, numeracy, literacy, no NVR
        TEXT
      },

      {
        title: "Year 4 Class Size and Teaching Staff",
        body: "Year 4 classes have a maximum of 18 students. Each class is led by 2 teachers supported by 2 teaching assistants, ensuring every child receives focused attention and support throughout the lesson.",
        retrieval_text: <<~TEXT
          Title: Year 4 Class Size and Teaching Staff
          Body: Year 4 classes have a maximum of 18 students. Each class is led by 2 teachers supported by 2 teaching assistants, ensuring every child receives focused attention and support throughout the lesson.
          Synonyms and related terms: Year 4 class size, Year 4 teachers, Year 4 teaching assistants, how many children, Year 4 ratio
          Likely questions: How many children are in a Year 4 class? How many teachers are in Year 4? What is the class size for Year 4? Is Year 4 a small class?
          Keywords: Year 4, 18 students, 2 teachers, 2 teaching assistants, class size, small class
        TEXT
      },

      {
        title: "Year 4 Online Course",
        body: "The Year 4 online course replicates the in-person experience with live interactive lessons on Saturday mornings. All live lessons are recorded and made available to students. Pre-recorded lessons are also provided for flexible revision. Students receive identical books and homework to in-person groups and are assessed as part of the same cohort.",
        retrieval_text: <<~TEXT
          Title: Year 4 Online Course
          Body: The Year 4 online course replicates the in-person experience with live interactive lessons on Saturday mornings. All live lessons are recorded and made available to students. Pre-recorded lessons are also provided for flexible revision. Students receive identical books and homework to in-person groups and are assessed as part of the same cohort.
          Synonyms and related terms: Year 4 online, Y4 online, Year 4 remote, Year 4 virtual, Year 4 live lessons, Year 4 Saturday online
          Likely questions: Is Year 4 available online? Are Year 4 online lessons live? Can my Year 4 child learn from home? Does Year 4 online mirror the in-person course? When are Year 4 online lessons?
          Keywords: Year 4, online, live lessons, Saturday, recorded, pre-recorded, identical homework, same cohort
        TEXT
      },

      {
        title: "Year 4 In-Person Course",
        body: "The Year 4 in-person course is held at our Harrow centre. Lessons run once weekly for 2.5 hours on Saturdays. Entry to the in-person course requires an Admissions Test in English and Maths to ensure children have the necessary foundation to join the existing cohort.",
        retrieval_text: <<~TEXT
          Title: Year 4 In-Person Course
          Body: The Year 4 in-person course is held at our Harrow centre. Lessons run once weekly for 2.5 hours on Saturdays. Entry to the in-person course requires an Admissions Test in English and Maths to ensure children have the necessary foundation to join the existing cohort.
          Synonyms and related terms: Year 4 in-person, Year 4 classroom, Year 4 Harrow, Year 4 face to face, attend Year 4 in person, Year 4 admissions
          Likely questions: Can my Year 4 child attend in person? Where are Year 4 lessons held? Does Year 4 in-person require a test? How long are Year 4 in-person lessons? Is there an admissions test for Year 4?
          Keywords: Year 4, in-person, Harrow, Saturday, 2.5 hours, admissions test, English, Maths, cohort
        TEXT
      },

      # ── Year 5 ────────────────────────────────────────────────────────────

      {
        title: "Year 5 Course Overview",
        body: "The Year 5 course is our most comprehensive 11+ preparation programme. It covers English, Mathematics, Verbal Reasoning and Non-Verbal Reasoning, fully preparing children for all subjects and relevant exam boards for their target schools. The course is available in-person at Harrow and online via live interactive Saturday lessons.",
        retrieval_text: <<~TEXT
          Title: Year 5 Course Overview
          Body: The Year 5 course is our most comprehensive 11+ preparation programme. It covers English, Mathematics, Verbal Reasoning and Non-Verbal Reasoning, fully preparing children for all subjects and relevant exam boards for their target schools. The course is available in-person at Harrow and online via live interactive Saturday lessons.
          Synonyms and related terms: Year 5, Y5, Yr5, year five, 11+ Year 5, eleven plus Year 5, Year 5 tuition, comprehensive 11+ prep
          Likely questions: Do you offer Year 5 tuition? What does Year 5 cover? Is Year 5 the main 11+ preparation year? Can my Year 5 child join? What year groups do you teach?
          Keywords: Year 5, English, Maths, Mathematics, Verbal Reasoning, Non-Verbal Reasoning, VR, NVR, GL Assessment, CEM, ISEB, online, in-person, Saturday
        TEXT
      },

      {
        title: "Year 5 Subjects",
        body: "The Year 5 course covers English, Mathematics, Verbal Reasoning and Non-Verbal Reasoning. This is the first year that Non-Verbal Reasoning (NVR) is introduced. The course prepares children across all four subjects for GL Assessment, CEM and ISEB exam boards.",
        retrieval_text: <<~TEXT
          Title: Year 5 Subjects
          Body: The Year 5 course covers English, Mathematics, Verbal Reasoning and Non-Verbal Reasoning. This is the first year that Non-Verbal Reasoning (NVR) is introduced. The course prepares children across all four subjects for GL Assessment, CEM and ISEB exam boards.
          Synonyms and related terms: Year 5 subjects, Year 5 curriculum, Year 5 NVR, Year 5 non-verbal reasoning, Year 5 verbal reasoning, Year 5 English Maths, what Year 5 covers
          Likely questions: What subjects are in Year 5? Does Year 5 include NVR? When is non-verbal reasoning introduced? Does Year 5 cover all four 11+ subjects? What does my Year 5 child study?
          Keywords: Year 5, English, Maths, Mathematics, Verbal Reasoning, VR, Non-Verbal Reasoning, NVR, GL Assessment, CEM, ISEB, all four subjects
        TEXT
      },

      {
        title: "Year 5 Online Course",
        body: "The Year 5 online course offers live interactive lessons on Saturday mornings at 9.00am, closely mirroring the in-person experience. All live sessions are recorded and made available to students. Pre-recorded lessons are also provided. No admissions test is required to join the online course.",
        retrieval_text: <<~TEXT
          Title: Year 5 Online Course
          Body: The Year 5 online course offers live interactive lessons on Saturday mornings at 9.00am, closely mirroring the in-person experience. All live sessions are recorded and made available to students. Pre-recorded lessons are also provided. No admissions test is required to join the online course.
          Synonyms and related terms: Year 5 online, Y5 online, Year 5 remote, Year 5 virtual, Year 5 live lessons, Year 5 Saturday online, online Year 5 tuition
          Likely questions: Is Year 5 available online? Are Year 5 online lessons live? What time are Year 5 online lessons? Can my child do Year 5 from home? Do I need to take a test to join Year 5 online?
          Keywords: Year 5, online, live, interactive, Saturday, 9am, recorded, no admissions test, pre-recorded
        TEXT
      },

      {
        title: "Year 5 In-Person Course",
        body: "Year 5 in-person lessons are held at our Harrow centre once weekly on Saturdays. Morning sessions start at approximately 8.45am and afternoon sessions at approximately 1.00pm. Each lesson is 3.5 hours long. An Admissions Test is required for in-person entry.",
        retrieval_text: <<~TEXT
          Title: Year 5 In-Person Course
          Body: Year 5 in-person lessons are held at our Harrow centre once weekly on Saturdays. Morning sessions start at approximately 8.45am and afternoon sessions at approximately 1.00pm. Each lesson is 3.5 hours long. An Admissions Test is required for in-person entry.
          Synonyms and related terms: Year 5 in-person, Year 5 classroom, Year 5 Harrow, Year 5 face to face, attend Year 5 in person, Year 5 Saturday lessons
          Likely questions: Can my Year 5 child attend in person? What time are Year 5 in-person lessons? How long are Year 5 lessons? Where are Year 5 classes held? Is there a test to join Year 5 in person?
          Keywords: Year 5, in-person, Harrow, Saturday, 8.45am, 1pm, 3.5 hours, admissions test
        TEXT
      },

      {
        title: "Year 5 Exam Board Preparation",
        body: "The Year 5 course provides specialist training and comprehensively prepares children for GL Assessment, CEM (Centre for Evaluation and Monitoring) and ISEB exam boards. The course is thorough enough to prepare children for most local grammar and independent schools without requiring additional specialist tuition.",
        retrieval_text: <<~TEXT
          Title: Year 5 Exam Board Preparation
          Body: The Year 5 course provides specialist training and comprehensively prepares children for GL Assessment, CEM (Centre for Evaluation and Monitoring) and ISEB exam boards. The course is thorough enough to prepare children for most local grammar and independent schools without requiring additional specialist tuition.
          Synonyms and related terms: Year 5 exam boards, Year 5 GL, Year 5 CEM, Year 5 ISEB, eleven plus boards Year 5, grammar school Year 5, independent school Year 5
          Likely questions: Does Year 5 prepare for GL Assessment? Is CEM covered in Year 5? Does Year 5 cover ISEB? Which exam boards does Year 5 prepare for? Will Year 5 prepare my child for grammar school?
          Keywords: Year 5, GL Assessment, CEM, ISEB, grammar school, independent school, exam boards, comprehensive preparation
        TEXT
      },

      # ── Year 6 ────────────────────────────────────────────────────────────

      {
        title: "Year 6 Course Overview",
        body: "The Year 6 course is a 12-week intensive programme designed for children preparing for independent school entrance exams. It covers advanced Mathematics, English and Creative Writing, and Verbal and Non-Verbal Reasoning. Lessons continue over school half-term holidays. The course targets selective independent schools and covers ISEB and other independent school exam boards.",
        retrieval_text: <<~TEXT
          Title: Year 6 Course Overview
          Body: The Year 6 course is a 12-week intensive programme designed for children preparing for independent school entrance exams. It covers advanced Mathematics, English and Creative Writing, and Verbal and Non-Verbal Reasoning. Lessons continue over school half-term holidays. The course targets selective independent schools and covers ISEB and other independent school exam boards.
          Synonyms and related terms: Year 6, Y6, Yr6, year six, Year 6 tuition, independent school prep, senior school entrance, ISEB Year 6, Year 6 eleven plus
          Likely questions: Do you offer Year 6 tuition? What does the Year 6 course cover? Is Year 6 for independent schools? How long is the Year 6 course? Does Year 6 continue during half term?
          Keywords: Year 6, advanced Maths, English, Creative Writing, Verbal Reasoning, Non-Verbal Reasoning, NVR, VR, 12 weeks, ISEB, independent school, half-term
        TEXT
      },

      {
        title: "Year 6 Lesson Schedule",
        body: "Year 6 lessons run twice weekly. Options include Tuesdays 5.00pm–7.15pm (Maths and Reasoning) and Fridays 5.00pm–6.00pm (English), or alternatively Tuesdays 5.00pm–6.00pm (English) and Fridays 5.00pm–7.15pm (Maths and Reasoning). Lessons continue through school half-term holidays.",
        retrieval_text: <<~TEXT
          Title: Year 6 Lesson Schedule
          Body: Year 6 lessons run twice weekly. Options include Tuesdays 5.00pm–7.15pm (Maths and Reasoning) and Fridays 5.00pm–6.00pm (English), or alternatively Tuesdays 5.00pm–6.00pm (English) and Fridays 5.00pm–7.15pm (Maths and Reasoning). Lessons continue through school half-term holidays.
          Synonyms and related terms: Year 6 schedule, Year 6 timetable, Year 6 lesson times, when are Year 6 lessons, Year 6 days, Year 6 twice weekly
          Likely questions: When are Year 6 lessons? How often does Year 6 meet? What days are Year 6 classes? What time do Year 6 lessons start? Does Year 6 run on Tuesdays and Fridays?
          Keywords: Year 6, Tuesday, Friday, 5pm, twice weekly, Maths, Reasoning, English, half-term, 7.15pm, 6pm
        TEXT
      },

      {
        title: "Year 6 Subjects in Depth",
        body: "The Year 6 Maths content goes beyond Year 5 and introduces topics including algebra, sequences, shapes, area, volume, time, logical reasoning, permutations, pathing and number bases. English and Creative Writing focus on timed creative writing under exam conditions and past paper analysis. Reasoning covers a range of verbal, non-verbal and general entrance assessment styles common in independent school papers.",
        retrieval_text: <<~TEXT
          Title: Year 6 Subjects in Depth
          Body: The Year 6 Maths content goes beyond Year 5 and introduces topics including algebra, sequences, shapes, area, volume, time, logical reasoning, permutations, pathing and number bases. English and Creative Writing focus on timed creative writing under exam conditions and past paper analysis. Reasoning covers a range of verbal, non-verbal and general entrance assessment styles common in independent school papers.
          Synonyms and related terms: Year 6 topics, Year 6 maths syllabus, Year 6 advanced maths, Year 6 creative writing, Year 6 reasoning, independent school paper preparation
          Likely questions: What maths topics does Year 6 cover? What is taught in Year 6 English? Does Year 6 do creative writing? What reasoning topics are in Year 6? How advanced is the Year 6 maths?
          Keywords: Year 6, algebra, sequences, shapes, area, volume, logical reasoning, permutations, creative writing, timed, past papers, verbal reasoning, non-verbal reasoning, NVR, VR, independent schools
        TEXT
      },

      # ── Intensive courses ─────────────────────────────────────────────────

      {
        title: "Intensive Courses Overview",
        body: "We offer intensive holiday courses covering Mathematics, English and Creative Writing. These are short focused courses of 2 to 4 days with sessions of 3 to 4 hours per day. They are designed for targeted revision and exam preparation during school holidays, particularly Easter and Summer. In-person intensive courses cost £450–£550.",
        retrieval_text: <<~TEXT
          Title: Intensive Courses Overview
          Body: We offer intensive holiday courses covering Mathematics, English and Creative Writing. These are short focused courses of 2 to 4 days with sessions of 3 to 4 hours per day. They are designed for targeted revision and exam preparation during school holidays, particularly Easter and Summer. In-person intensive courses cost £450–£550.
          Synonyms and related terms: intensive course, holiday course, crash course, revision course, Easter course, Summer course, short course, booster course
          Likely questions: Do you offer intensive courses? Are there holiday courses available? Do you run Easter revision classes? What intensive courses do you offer? Is there a short course for exam prep?
          Keywords: intensive, holiday, Easter, Summer, Maths, English, Creative Writing, 2-4 days, 3-4 hours, £450, £550
        TEXT
      },

      {
        title: "Intensive Creative Writing Course",
        body: "The intensive Creative Writing course runs for 4 days with 3.5 hours of tuition per day. It is held during Easter and Summer holidays and is designed to improve and enhance children's creative writing skills for success in 11+ and independent school exams. Sessions focus on timed writing practice, structuring responses and building vocabulary.",
        retrieval_text: <<~TEXT
          Title: Intensive Creative Writing Course
          Body: The intensive Creative Writing course runs for 4 days with 3.5 hours of tuition per day. It is held during Easter and Summer holidays and is designed to improve and enhance children's creative writing skills for success in 11+ and independent school exams. Sessions focus on timed writing practice, structuring responses and building vocabulary.
          Synonyms and related terms: creative writing intensive, creative writing course, writing holiday course, Easter writing, Summer writing, 11+ creative writing, English intensive
          Likely questions: Is there a creative writing course? Do you run a writing intensive? When is the creative writing course? How long is the creative writing intensive? Does the creative writing course run in the holidays?
          Keywords: Creative Writing, intensive, 4 days, 3.5 hours, Easter, Summer, timed writing, vocabulary, independent school, 11+
        TEXT
      },

      {
        title: "Intensive Maths and English Courses",
        body: "Intensive Maths and English courses are available as 2 to 4 day courses with 3 to 4 hour sessions per day. They focus on key topic revision and exam technique. These courses are available during school holidays and are suitable for children who want targeted preparation in a specific subject.",
        retrieval_text: <<~TEXT
          Title: Intensive Maths and English Courses
          Body: Intensive Maths and English courses are available as 2 to 4 day courses with 3 to 4 hour sessions per day. They focus on key topic revision and exam technique. These courses are available during school holidays and are suitable for children who want targeted preparation in a specific subject.
          Synonyms and related terms: intensive Maths, intensive English, Maths holiday course, English holiday course, maths revision course, English revision course, subject intensive
          Likely questions: Is there a maths intensive course? Do you offer an English intensive? Can my child just do a maths course? Are there subject-specific holiday courses? How long are the maths intensives?
          Keywords: intensive, Maths, English, 2-4 days, 3-4 hours, holiday, revision, exam technique
        TEXT
      },

      # ── Online vs in-person ───────────────────────────────────────────────

      {
        title: "Online Course — General",
        body: "Our online courses are available nationwide and replicate the in-person curriculum exactly. Year 4 and Year 5 online courses feature live interactive lessons on Saturday mornings. The Year 3 online course uses pre-recorded video tutorials. No admissions test is required for online courses. Online courses have grown in popularity due to their on-demand accessibility and flexibility.",
        retrieval_text: <<~TEXT
          Title: Online Course — General
          Body: Our online courses are available nationwide and replicate the in-person curriculum exactly. Year 4 and Year 5 online courses feature live interactive lessons on Saturday mornings. The Year 3 online course uses pre-recorded video tutorials. No admissions test is required for online courses. Online courses have grown in popularity due to their on-demand accessibility and flexibility.
          Synonyms and related terms: online tuition, remote learning, virtual lessons, online 11+ course, learn from home, online eleven plus, nationwide tuition
          Likely questions: Do you offer online tuition? Can my child do the course online? Are your online lessons live? Do I need to be near Harrow to join? Is online available across the UK?
          Keywords: online, nationwide, live, interactive, Saturday, pre-recorded, no admissions test, flexible, Year 3, Year 4, Year 5
        TEXT
      },

      {
        title: "In-Person Course — General",
        body: "In-person courses are held at our tuition centre in Harrow. An Admissions Test in English and Maths is required before joining to ensure each child has the necessary foundation for the course and can integrate with the existing cohort. In-person lessons include the same books and materials as online students.",
        retrieval_text: <<~TEXT
          Title: In-Person Course — General
          Body: In-person courses are held at our tuition centre in Harrow. An Admissions Test in English and Maths is required before joining to ensure each child has the necessary foundation for the course and can integrate with the existing cohort. In-person lessons include the same books and materials as online students.
          Synonyms and related terms: in-person tuition, classroom lessons, face to face tuition, Harrow tuition centre, attend in person, physical lessons, local tuition
          Likely questions: Where are your in-person classes? Do I need a test to attend in person? Is there a classroom option? Where is your tuition centre? Do you have a physical location?
          Keywords: in-person, Harrow, admissions test, English, Maths, cohort, classroom, books, materials
        TEXT
      },

      {
        title: "Online vs In-Person — What's the Same",
        body: "Both online and in-person courses follow exactly the same lesson plans, curriculum, content and resources. Students on both courses receive identical books and homework. All students — whether online or in-person — are monitored and assessed as one cohort, meaning they are tracked and ranked together.",
        retrieval_text: <<~TEXT
          Title: Online vs In-Person — What's the Same
          Body: Both online and in-person courses follow exactly the same lesson plans, curriculum, content and resources. Students on both courses receive identical books and homework. All students — whether online or in-person — are monitored and assessed as one cohort, meaning they are tracked and ranked together.
          Synonyms and related terms: online vs in-person, online versus classroom, difference between online and in-person, is online the same as in-person
          Likely questions: Is online the same as in-person? Do online students get the same materials? Is the online curriculum identical? Are online and in-person students assessed together? Will my child miss out by doing it online?
          Keywords: online, in-person, same curriculum, identical books, same homework, one cohort, assessed together, same content
        TEXT
      },

      {
        title: "Online vs In-Person — Key Differences",
        body: "The key differences between online and in-person courses are: (1) Year 3 online uses pre-recorded videos, while in-person is live. (2) Year 4 and 5 online are live but remote; in-person is at Harrow. (3) In-person requires an Admissions Test; online does not. (4) Live online lessons are recorded and available to rewatch — an advantage for revision.",
        retrieval_text: <<~TEXT
          Title: Online vs In-Person — Key Differences
          Body: The key differences between online and in-person courses are: (1) Year 3 online uses pre-recorded videos, while in-person is live. (2) Year 4 and 5 online are live but remote; in-person is at Harrow. (3) In-person requires an Admissions Test; online does not. (4) Live online lessons are recorded and available to rewatch — an advantage for revision.
          Synonyms and related terms: differences between online and in-person, online vs classroom, should I choose online or in-person, which is better online or in-person
          Likely questions: What is the difference between online and in-person? Should my child do online or in-person? Is online as good as in-person? Do online students need to take an admissions test? Can online students rewatch lessons?
          Keywords: online, in-person, pre-recorded, live, admissions test, recorded lessons, Harrow, differences, Year 3, Year 4, Year 5
        TEXT
      },

      {
        title: "Admissions Test for In-Person Courses",
        body: "Entry to all in-person courses requires an Admissions Test in English and Maths. This test ensures that each child has the necessary foundation in numeracy and literacy to comfortably follow the course and integrate with the existing cohort. The test is not required for online courses.",
        retrieval_text: <<~TEXT
          Title: Admissions Test for In-Person Courses
          Body: Entry to all in-person courses requires an Admissions Test in English and Maths. This test ensures that each child has the necessary foundation in numeracy and literacy to comfortably follow the course and integrate with the existing cohort. The test is not required for online courses.
          Synonyms and related terms: admissions test, entry test, entrance test, assessment, in-person admissions, test before joining, placement test
          Likely questions: Do I need to take a test to join? Is there an admissions test? What does the admissions test cover? Do online students need a test? How do I get into the in-person course?
          Keywords: admissions test, in-person, English, Maths, foundation, numeracy, literacy, no test online
        TEXT
      },

      # ── Subjects ──────────────────────────────────────────────────────────

      {
        title: "Verbal Reasoning in the 11+",
        body: "Verbal Reasoning (VR) is a core subject in the 11+ exam. It tests a child's ability to understand and reason using words and language. Common question types include word codes, analogies, hidden words, letter series and vocabulary. Verbal Reasoning is taught from Year 4 onwards in our courses.",
        retrieval_text: <<~TEXT
          Title: Verbal Reasoning in the 11+
          Body: Verbal Reasoning (VR) is a core subject in the 11+ exam. It tests a child's ability to understand and reason using words and language. Common question types include word codes, analogies, hidden words, letter series and vocabulary. Verbal Reasoning is taught from Year 4 onwards in our courses.
          Synonyms and related terms: verbal reasoning, VR, verbal, word reasoning, language reasoning, 11+ VR, verbal questions, 11+ verbal
          Likely questions: What is verbal reasoning? Does the 11+ include verbal reasoning? When is verbal reasoning taught? Does my child need verbal reasoning? What does verbal reasoning involve?
          Keywords: Verbal Reasoning, VR, words, analogies, codes, word series, vocabulary, Year 4, Year 5, 11+
        TEXT
      },

      {
        title: "Non-Verbal Reasoning in the 11+",
        body: "Non-Verbal Reasoning (NVR) tests a child's ability to understand and analyse visual information — shapes, patterns, sequences and spatial reasoning — without relying on language. It is introduced in Year 5 and is assessed by GL Assessment, CEM and ISEB exam boards. NVR is particularly important for children targeting selective grammar and independent schools.",
        retrieval_text: <<~TEXT
          Title: Non-Verbal Reasoning in the 11+
          Body: Non-Verbal Reasoning (NVR) tests a child's ability to understand and analyse visual information — shapes, patterns, sequences and spatial reasoning — without relying on language. It is introduced in Year 5 and is assessed by GL Assessment, CEM and ISEB exam boards. NVR is particularly important for children targeting selective grammar and independent schools.
          Synonyms and related terms: non-verbal reasoning, NVR, non verbal reasoning, shapes reasoning, pattern recognition, spatial reasoning, visual reasoning, 11+ NVR
          Likely questions: What is non-verbal reasoning? Does the 11+ include NVR? When is NVR taught? Does my child need non-verbal reasoning? What does NVR involve?
          Keywords: Non-Verbal Reasoning, NVR, shapes, patterns, sequences, spatial, visual, Year 5, GL Assessment, CEM, ISEB, grammar school, independent school
        TEXT
      },

      {
        title: "English in the 11+",
        body: "English in our courses covers reading comprehension, vocabulary, grammar, punctuation and creative writing. In Years 4 and 5, the focus is on comprehension and vocabulary. In Year 6, creative writing under timed examination conditions is a major focus, alongside analysis of independent school past papers.",
        retrieval_text: <<~TEXT
          Title: English in the 11+
          Body: English in our courses covers reading comprehension, vocabulary, grammar, punctuation and creative writing. In Years 4 and 5, the focus is on comprehension and vocabulary. In Year 6, creative writing under timed examination conditions is a major focus, alongside analysis of independent school past papers.
          Synonyms and related terms: English tuition, 11+ English, comprehension, reading comprehension, vocabulary, grammar, creative writing, English skills
          Likely questions: What English topics are covered? Does the 11+ test English? Is creative writing part of the course? What kind of English questions come up in the 11+? Does English include comprehension?
          Keywords: English, comprehension, reading, vocabulary, grammar, punctuation, creative writing, timed, Year 4, Year 5, Year 6, past papers
        TEXT
      },

      {
        title: "Maths in the 11+",
        body: "Mathematics in our courses covers numeracy, arithmetic, problem solving and applied maths. In Year 4 and 5, the focus is on solidifying core numeracy and problem-solving skills. The Year 6 course introduces advanced topics including algebra, sequences, area, volume, logical reasoning, permutations, pathing and number bases.",
        retrieval_text: <<~TEXT
          Title: Maths in the 11+
          Body: Mathematics in our courses covers numeracy, arithmetic, problem solving and applied maths. In Year 4 and 5, the focus is on solidifying core numeracy and problem-solving skills. The Year 6 course introduces advanced topics including algebra, sequences, area, volume, logical reasoning, permutations, pathing and number bases.
          Synonyms and related terms: maths tuition, 11+ maths, mathematics, numeracy, arithmetic, problem solving, algebra, 11+ numeracy
          Likely questions: What maths is covered in the 11+? Does my child need maths tuition? What kind of maths questions come up? Is algebra in the 11+? What maths topics are taught?
          Keywords: Maths, Mathematics, numeracy, arithmetic, problem solving, algebra, sequences, area, volume, logical reasoning, Year 4, Year 5, Year 6
        TEXT
      },

      # ── Exam boards ───────────────────────────────────────────────────────

      {
        title: "GL Assessment Exam Board",
        body: "GL Assessment (Granada Learning) is one of the most widely used 11+ exam boards in the UK, used by many grammar schools and local education authorities. GL papers are published in advance and the format is generally consistent, allowing for structured preparation. Our courses prepare children thoroughly for GL Assessment in all four subjects.",
        retrieval_text: <<~TEXT
          Title: GL Assessment Exam Board
          Body: GL Assessment (Granada Learning) is one of the most widely used 11+ exam boards in the UK, used by many grammar schools and local education authorities. GL papers are published in advance and the format is generally consistent, allowing for structured preparation. Our courses prepare children thoroughly for GL Assessment in all four subjects.
          Synonyms and related terms: GL, GL Assessment, Granada Learning, NFER, grammar school exam board, GL papers, GL test
          Likely questions: Do you prepare for GL Assessment? What is GL Assessment? Which schools use GL? Does your course cover GL? Is GL the same as Granada Learning?
          Keywords: GL Assessment, Granada Learning, NFER, grammar school, local education authority, structured preparation, 11+
        TEXT
      },

      {
        title: "CEM Exam Board",
        body: "CEM (Centre for Evaluation and Monitoring, Durham University) is an 11+ exam board introduced to make the exam harder to teach to. CEM does not publish practice papers and deliberately changes the format between exams to minimise rote preparation. Our Year 5 course provides strong preparation for CEM through building genuine understanding and flexibility across all four subjects.",
        retrieval_text: <<~TEXT
          Title: CEM Exam Board
          Body: CEM (Centre for Evaluation and Monitoring, Durham University) is an 11+ exam board introduced to make the exam harder to teach to. CEM does not publish practice papers and deliberately changes the format between exams to minimise rote preparation. Our Year 5 course provides strong preparation for CEM through building genuine understanding and flexibility across all four subjects.
          Synonyms and related terms: CEM, Centre for Evaluation and Monitoring, Durham University, CEM exam, CEM 11+, CEM test, CEM preparation
          Likely questions: Do you prepare for CEM? What is CEM? How is CEM different from GL? Does CEM publish practice papers? Is CEM harder to prepare for?
          Keywords: CEM, Centre for Evaluation and Monitoring, Durham University, no practice papers, format changes, genuine understanding, Year 5
        TEXT
      },

      {
        title: "ISEB Exam Board",
        body: "ISEB (Independent Schools Examination Board) is used by many independent (private) schools for their entrance assessments. ISEB papers are typically used in Year 6 assessments for selective independent senior schools. Our Year 5 and Year 6 courses prepare children for ISEB across English, Maths, Verbal Reasoning and Non-Verbal Reasoning.",
        retrieval_text: <<~TEXT
          Title: ISEB Exam Board
          Body: ISEB (Independent Schools Examination Board) is used by many independent (private) schools for their entrance assessments. ISEB papers are typically used in Year 6 assessments for selective independent senior schools. Our Year 5 and Year 6 courses prepare children for ISEB across English, Maths, Verbal Reasoning and Non-Verbal Reasoning.
          Synonyms and related terms: ISEB, Independent Schools Examination Board, independent school exam, private school exam, ISEB prep, ISEB 11+
          Likely questions: Do you prepare for ISEB? What is ISEB? Which schools use ISEB? Does your course cover independent school exams? Is ISEB covered in Year 5?
          Keywords: ISEB, Independent Schools Examination Board, independent school, private school, Year 5, Year 6, English, Maths, Verbal Reasoning, Non-Verbal Reasoning
        TEXT
      },

      {
        title: "GL Assessment vs CEM — Key Differences",
        body: "GL Assessment and CEM are the two most common 11+ exam boards. GL papers are published and follow a consistent format, making structured preparation straightforward. CEM papers are not published, and the format changes each year to reduce the effectiveness of rote learning. Both boards test English, Maths and Verbal Reasoning; GL typically includes NVR while CEM's subject mix varies by school. Our courses develop genuine skills that prepare children for both.",
        retrieval_text: <<~TEXT
          Title: GL Assessment vs CEM — Key Differences
          Body: GL Assessment and CEM are the two most common 11+ exam boards. GL papers are published and follow a consistent format, making structured preparation straightforward. CEM papers are not published, and the format changes each year to reduce the effectiveness of rote learning. Both boards test English, Maths and Verbal Reasoning; GL typically includes NVR while CEM's subject mix varies by school. Our courses develop genuine skills that prepare children for both.
          Synonyms and related terms: GL vs CEM, difference between GL and CEM, CEM or GL, which exam board, GL CEM comparison, how are GL and CEM different
          Likely questions: What is the difference between GL and CEM? Which is harder GL or CEM? Does my child need to know which exam board they are sitting? Does your course cover both GL and CEM? How do GL and CEM differ?
          Keywords: GL Assessment, CEM, difference, published papers, format changes, English, Maths, Verbal Reasoning, NVR, preparation
        TEXT
      },

      # ── Class format & teaching ───────────────────────────────────────────

      {
        title: "Class Sizes",
        body: "Our classes have a maximum of 16 to 18 students depending on the course, ensuring a focused learning environment. Each class is supported by at least 2 teachers and 2 graduate or undergraduate teaching assistants. This ratio means every child receives close attention throughout the lesson.",
        retrieval_text: <<~TEXT
          Title: Class Sizes
          Body: Our classes have a maximum of 16 to 18 students depending on the course, ensuring a focused learning environment. Each class is supported by at least 2 teachers and 2 graduate or undergraduate teaching assistants. This ratio means every child receives close attention throughout the lesson.
          Synonyms and related terms: class size, class sizes, how many students, students in a class, students per class, how many children per class, how many pupils, pupils per class, teacher ratio, student to teacher ratio, small class, class numbers, class capacity, number of students, maximum students
          Likely questions: How many students are in a class? How many children are in a class? What is the class size? Is it a small class? How many teachers are there? What is the teacher to student ratio? How many students per class? What is the maximum class size? How many pupils are in each class?
          Keywords: class size, 16 students, 18 students, students, pupils, children, 2 teachers, 2 teaching assistants, graduate, undergraduate, focused, ratio, maximum, capacity
        TEXT
      },

      {
        title: "Teaching Staff",
        body: "Each class at Eleven Plus Exams Tuition is led by at least 2 teachers and supported by a minimum of 2 graduate or undergraduate teaching assistants. All teaching staff are experienced in 11+ preparation and DBS-checked. Mock exams are supervised by DBS-checked staff.",
        retrieval_text: <<~TEXT
          Title: Teaching Staff
          Body: Each class at Eleven Plus Exams Tuition is led by at least 2 teachers and supported by a minimum of 2 graduate or undergraduate teaching assistants. All teaching staff are experienced in 11+ preparation and DBS-checked. Mock exams are supervised by DBS-checked staff.
          Synonyms and related terms: teachers, teaching assistants, tutors, staff, who teaches, DBS checked, qualified teachers, teaching team
          Likely questions: Who teaches the classes? Are the teachers qualified? Are staff DBS checked? How many teachers are there? What qualifications do the tutors have?
          Keywords: teachers, teaching assistants, graduate, undergraduate, DBS checked, experienced, 11+ preparation, 2 teachers, 2 TAs
        TEXT
      },

      {
        title: "Materials and Books Included",
        body: "All course fees at Eleven Plus Exams Tuition are all-inclusive. This means course books, materials, mock exams and online access are all covered in the fee. There are no hidden costs. Students on both online and in-person courses receive identical books and materials.",
        retrieval_text: <<~TEXT
          Title: Materials and Books Included
          Body: All course fees at Eleven Plus Exams Tuition are all-inclusive. This means course books, materials, mock exams and online access are all covered in the fee. There are no hidden costs. Students on both online and in-person courses receive identical books and materials.
          Synonyms and related terms: course materials, books included, all-inclusive, what's included, course resources, no extra costs, are books included
          Likely questions: Are books included? Do I need to buy extra materials? Is the course all-inclusive? What does the fee cover? Are there extra costs?
          Keywords: all-inclusive, books included, materials, mock exams, online access, no hidden costs, same for online and in-person
        TEXT
      },

      {
        title: "Half-Term Lessons",
        body: "Lessons at Eleven Plus Exams Tuition generally run during school half-term holidays to maintain consistent progress. The only exceptions are certain dates around the Christmas and Easter period. This ensures that children keep up their pace of learning and don't lose ground during school breaks.",
        retrieval_text: <<~TEXT
          Title: Half-Term Lessons
          Body: Lessons at Eleven Plus Exams Tuition generally run during school half-term holidays to maintain consistent progress. The only exceptions are certain dates around the Christmas and Easter period. This ensures that children keep up their pace of learning and don't lose ground during school breaks.
          Synonyms and related terms: half term, school holidays, do lessons run in half term, lessons during holidays, Christmas break, Easter break
          Likely questions: Do lessons run during half term? Are there classes in the school holidays? Does tuition continue over half term? When do lessons stop? Are there breaks over Christmas?
          Keywords: half-term, school holidays, lessons continue, Christmas, Easter, consistent progress, Year 6, Year 4, Year 5
        TEXT
      },

      # ── Progress monitoring ───────────────────────────────────────────────

      {
        title: "Homework and Weekly Tracking",
        body: "All courses include detailed weekly homework tracking. Our technology monitors students' progress on both class work and homework, tracking speed and accuracy. Parents can see how their child is progressing week by week. Students are typically expected to commit 3 to 4 hours per week to homework.",
        retrieval_text: <<~TEXT
          Title: Homework and Weekly Tracking
          Body: All courses include detailed weekly homework tracking. Our technology monitors students' progress on both class work and homework, tracking speed and accuracy. Parents can see how their child is progressing week by week. Students are typically expected to commit 3 to 4 hours per week to homework.
          Synonyms and related terms: homework, weekly homework, homework tracking, how much homework, study at home, parent progress updates
          Likely questions: How much homework is there? Is homework set each week? How is homework tracked? Can I see my child's homework progress? How many hours of homework per week?
          Keywords: homework, weekly tracking, 3-4 hours, speed, accuracy, parents, progress, class work, technology
        TEXT
      },

      {
        title: "End-of-Term Progress Reports",
        body: "Students receive a detailed end-of-term report that analyses data from homework, class activities and end-of-term tests. The report provides an overall ranking within the cohort and individual rankings by subject. This helps parents and children understand strengths and areas for improvement.",
        retrieval_text: <<~TEXT
          Title: End-of-Term Progress Reports
          Body: Students receive a detailed end-of-term report that analyses data from homework, class activities and end-of-term tests. The report provides an overall ranking within the cohort and individual rankings by subject. This helps parents and children understand strengths and areas for improvement.
          Synonyms and related terms: progress report, end of term report, term report, how is progress measured, subject ranking, cohort ranking, feedback report
          Likely questions: Do you provide progress reports? How do I know how my child is doing? What is included in the term report? How is my child ranked? When do we get feedback?
          Keywords: end-of-term report, homework, class activities, end-of-term tests, overall ranking, subject ranking, cohort, feedback, strengths, improvement
        TEXT
      },

      {
        title: "11+ Peer Compare System",
        body: "Eleven Plus Exams Tuition has developed an exclusive in-house software called the 11+ Peer Compare™ system. This provides detailed feedback reports with raw scores per subject and subject percentile rankings within the cohort. It allows parents and children to benchmark performance accurately against peers.",
        retrieval_text: <<~TEXT
          Title: 11+ Peer Compare System
          Body: Eleven Plus Exams Tuition has developed an exclusive in-house software called the 11+ Peer Compare™ system. This provides detailed feedback reports with raw scores per subject and subject percentile rankings within the cohort. It allows parents and children to benchmark performance accurately against peers.
          Synonyms and related terms: Peer Compare, 11+ Peer Compare, performance tracking, benchmarking, percentile ranking, raw scores, cohort comparison, online system
          Likely questions: What is the Peer Compare system? How do you track performance? Can I see percentile rankings? How is my child compared to others? Do you have an online tracking system?
          Keywords: 11+ Peer Compare, raw scores, percentile rankings, cohort, feedback, benchmarking, performance tracking, in-house software
        TEXT
      },

      {
        title: "Mock Exams — What They Are",
        body: "Mock exams at Eleven Plus Exams Tuition are conducted under actual examination conditions in a safe environment supervised by DBS-checked staff. Each mock is tailored to reflect the current format of individual examining boards. After each mock, a detailed report is provided so parents can gauge their child's performance against their peer group.",
        retrieval_text: <<~TEXT
          Title: Mock Exams — What They Are
          Body: Mock exams at Eleven Plus Exams Tuition are conducted under actual examination conditions in a safe environment supervised by DBS-checked staff. Each mock is tailored to reflect the current format of individual examining boards. After each mock, a detailed report is provided so parents can gauge their child's performance against their peer group.
          Synonyms and related terms: mock exam, mock test, practice exam, practice test, 11+ mock, exam simulation, mock papers
          Likely questions: Do you offer mock exams? What are the mock exams like? Are mock exams under real exam conditions? Do I get a report after a mock? Are mocks DBS supervised?
          Keywords: mock exam, examination conditions, DBS checked, tailored, exam board, report, peer group, performance
        TEXT
      },

      {
        title: "Mock Exam Schedule",
        body: "Our 11+ mock examination sessions run from mid-March to mid-September each year, covering both grammar school and independent school entry. Mocks are held for all major exam boards. The schedule is published on our calendar page. Mock exams are included as part of all-inclusive course fees.",
        retrieval_text: <<~TEXT
          Title: Mock Exam Schedule
          Body: Our 11+ mock examination sessions run from mid-March to mid-September each year, covering both grammar school and independent school entry. Mocks are held for all major exam boards. The schedule is published on our calendar page. Mock exams are included as part of all-inclusive course fees.
          Synonyms and related terms: mock exam dates, when are mocks, mock schedule, mock timetable, mock exam calendar, when do mocks run
          Likely questions: When are the mock exams? How often are mocks held? When do mock exams start? Are mocks included in the course fee? Where can I see the mock schedule?
          Keywords: mock exams, March, September, grammar school, independent school, calendar, all-inclusive, included in fee, schedule
        TEXT
      },

      # ── Year progression ──────────────────────────────────────────────────

      {
        title: "Progression from Year 4 to Year 5",
        body: "At the end of Year 4, teachers assess each child's suitability for Year 5 based on their performance throughout the year — including class participation, behaviour, test results and homework commitment. The vast majority of children who complete Year 4 are accepted into Year 5. Teachers work closely with parents to support each child's development.",
        retrieval_text: <<~TEXT
          Title: Progression from Year 4 to Year 5
          Body: At the end of Year 4, teachers assess each child's suitability for Year 5 based on their performance throughout the year — including class participation, behaviour, test results and homework commitment. The vast majority of children who complete Year 4 are accepted into Year 5. Teachers work closely with parents to support each child's development.
          Synonyms and related terms: Year 4 to Year 5, Year 5 entry, progression, moving up, can my child join Year 5, Year 4 completion, Year 5 eligibility
          Likely questions: Can my child move from Year 4 to Year 5? How does Year 5 entry work? Is Year 5 guaranteed after Year 4? What determines Year 5 entry? Will my child be accepted into Year 5?
          Keywords: Year 4 to Year 5, progression, class participation, behaviour, test results, homework, majority accepted, teacher assessment
        TEXT
      },

      {
        title: "Year 3 to Year 4 Priority Booking",
        body: "Children who complete the Year 3 course are given priority booking for the Year 4 course. This means they are offered a place in Year 4 before spaces are made available to new applicants. Priority booking gives parents peace of mind about continuity of tuition.",
        retrieval_text: <<~TEXT
          Title: Year 3 to Year 4 Priority Booking
          Body: Children who complete the Year 3 course are given priority booking for the Year 4 course. This means they are offered a place in Year 4 before spaces are made available to new applicants. Priority booking gives parents peace of mind about continuity of tuition.
          Synonyms and related terms: Year 3 to Year 4, priority booking, Year 4 place, Year 3 completion, guaranteed Year 4, Year 4 entry
          Likely questions: Does Year 3 guarantee a place in Year 4? What is priority booking? Will my child get into Year 4 after Year 3? How do I secure a Year 4 place? Is Year 4 booking automatic for Year 3 students?
          Keywords: Year 3, Year 4, priority booking, place guaranteed, continuity, new applicants
        TEXT
      },

    ]

    puts "Seeding #{entries.count} knowledge base entries..."
    created = 0
    skipped = 0

    entries.each do |attrs|
      if KnowledgeEntry.exists?(title: attrs[:title])
        puts "  SKIP — already exists: #{attrs[:title]}"
        skipped += 1
      else
        KnowledgeEntry.create!(attrs.merge(active: true))
        puts "  CREATED — #{attrs[:title]}"
        created += 1
      end
    end

    puts "\nDone. Created: #{created}, Skipped: #{skipped}."
    puts "Run 'rake kb:reembed' to generate embeddings for all entries." if ENV["OPENAI_API_KEY"].present?
    puts "Set OPENAI_API_KEY and run 'rake kb:reembed' to generate embeddings." unless ENV["OPENAI_API_KEY"].present?
  end
end
