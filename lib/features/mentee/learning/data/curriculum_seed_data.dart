import '../domain/curriculum.dart';

/// Fake/seed data for the mentee learning curriculum. Used only by
/// MockCurriculumRepository until the backend's progress/curriculum
/// endpoints are live. Keeping this separate from the repository means
/// the repository logic doesn't change when real data replaces this.
class CurriculumSeedData {
  CurriculumSeedData._();

  static const inProgressMentee = CurriculumProgress(
    cohortLabel: 'Cohort 2024-B',
    cpdHoursAccrued: 28.5,
    cpdHoursRequired: 40,
    chapters: [
      Chapter(
        id: 'chapter-1',
        number: 1,
        title: 'Maternal Physiology & Antenatal Basics',
        modules: [
          CurriculumModule(id: 'm1', number: 1, title: 'Maternal Physiology', lessons: [
            Lesson(id: 'l1', title: 'Cardiovascular Changes', durationMinutes: 15, status: LessonStatus.completed),
            Lesson(id: 'l2', title: 'Hormonal Changes', durationMinutes: 15, status: LessonStatus.completed),
          ]),
          CurriculumModule(id: 'm2', number: 2, title: 'Antenatal Screening', lessons: [
            Lesson(id: 'l3', title: 'First Trimester Screening', durationMinutes: 20, status: LessonStatus.completed),
            Lesson(id: 'l4', title: 'Risk Factor Assessment', durationMinutes: 20, status: LessonStatus.completed),
          ]),
        ],
      ),
      Chapter(
        id: 'chapter-2',
        number: 2,
        title: 'Intrapartum Care & Clinical Obstetric Skills',
        modules: [
          CurriculumModule(id: 'm3', number: 3, title: 'Stages of Labour', lessons: [
            Lesson(id: 'l5', title: 'First Stage Management', durationMinutes: 20, status: LessonStatus.completed),
          ]),
          CurriculumModule(id: 'm4', number: 4, title: 'Fundal Height Assessment & Palpation', lessons: [
            Lesson(id: 'l6', title: 'Symphysis-Fundal Height Principles', durationMinutes: 15, status: LessonStatus.completed),
            Lesson(id: 'l7', title: 'Fundal Height & Palpation Assessment', durationMinutes: 25, status: LessonStatus.inProgress, progressPercent: 75, isAudio: true),
            Lesson(id: 'l8', title: "Leopold's 4 Maneuvers Clinical", durationMinutes: 20, status: LessonStatus.completed),
            Lesson(id: 'l9', title: 'Clinical Verification Quiz', durationMinutes: 10, status: LessonStatus.notStarted),
          ]),
          CurriculumModule(id: 'm5', number: 5, title: 'Fetal Heart Rate Monitoring & CTG Interpretation', lessons: [
            Lesson(id: 'l10', title: 'Baseline Rate & Variability', durationMinutes: 15, status: LessonStatus.completed),
            Lesson(id: 'l11', title: 'Accelerations & Decelerations', durationMinutes: 15, status: LessonStatus.completed),
            Lesson(id: 'l12', title: 'CTG Classification', durationMinutes: 20, status: LessonStatus.notStarted),
            Lesson(id: 'l13', title: 'Case Review', durationMinutes: 15, status: LessonStatus.notStarted),
          ]),
          CurriculumModule(id: 'm6', number: 6, title: 'Partograph & Labor Progression Management', lessons: [
            Lesson(id: 'l14', title: 'Reading the Partograph', durationMinutes: 20, status: LessonStatus.completed),
            Lesson(id: 'l15', title: 'Action Line Decisions', durationMinutes: 20, status: LessonStatus.notStarted),
            Lesson(id: 'l16', title: 'Documentation Practice', durationMinutes: 15, status: LessonStatus.notStarted),
          ]),
        ],
      ),
      Chapter(
        id: 'chapter-3',
        number: 3,
        title: 'Postpartum Complications & Emergencies',
        modules: [
          CurriculumModule(id: 'm7', number: 7, title: 'Postpartum Haemorrhage', lessons: [
            Lesson(id: 'l17', title: 'Early Recognition', durationMinutes: 20, status: LessonStatus.notStarted),
          ]),
        ],
      ),
      Chapter(
        id: 'chapter-4',
        number: 4,
        title: 'Special Populations & Adolescent Obstetric Care',
        modules: [
          CurriculumModule(id: 'm8', number: 8, title: 'Adolescent-Specific Considerations', lessons: [
            Lesson(id: 'l18', title: 'Overview', durationMinutes: 15, status: LessonStatus.notStarted),
          ]),
        ],
      ),
    ],
  );

  static const freshMentee = CurriculumProgress(
    cohortLabel: 'Cohort 2024-B',
    cpdHoursAccrued: 0,
    cpdHoursRequired: 40,
    chapters: [
      Chapter(
        id: 'chapter-1',
        number: 1,
        title: 'Maternal Physiology & Antenatal Basics',
        modules: [
          CurriculumModule(id: 'm1', number: 1, title: 'Maternal Physiology', lessons: [
            Lesson(id: 'l1', title: 'Cardiovascular Changes', durationMinutes: 15, status: LessonStatus.notStarted),
            Lesson(id: 'l2', title: 'Hormonal Changes', durationMinutes: 15, status: LessonStatus.notStarted),
          ]),
        ],
      ),
    ],
  );
}