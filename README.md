# NUS MOOC Transacts Corpus
This is an annotated corpus of discussion forum threads from Massive Open Online Courses (MOOCs). The annotations are grounded on a pedagogy based discourse framework that adapts from and codifies 'transactivity' as proposed by Berkowitz and Gibbs, 1983. This is a simplified adadpation of their pedagogical/psychology based coding scheme, for instructor posts and replies in MOOC discussion forums.

We also propose inter-annotator agreement measures for a piecewise crowdsourcing annotation task to annotate the forum discussions with our modified taxonomy of transactive interventions.

However, due to privacy concerns and copyright claimed by MOOC platforms such as Coursera.org, we have encrypted the data. We also reserve the rights for access, use and distribution of the data. 

All rights reserved.

For access and use, please fill out the academic research purpose license form at http://bit.ly/wing-nus-mooc-transacts-corpus-request-form. 
We hold personal liability for the data to NUS and Coursera. We will review your request and get back to you within five (5) business days.

Citation:

If you use the corpus for your research please cite:

```
@phdthesis{Chandrasekaranthesis2019,
    author = {MUTHU KUMAR CHANDRASEKARAN},
    school   = {National University of Singapore},
    title = {A DISCOURSE CENTRIC FRAMEWORK FOR FACILITATING INSTRUCTOR INTERVENTION IN MOOC DISCUSSION FORUMS},
    year = {2019},
}
```

# Data
Repository contains serially annotated data for 3 natural language processing tasks on MOOC discussion threads. 
Task 1: 

## Annotation Categories

<table>
    <tr>
        <th>Level 1 Category</th>
        <th>Level 2 Category</th>
        <th>Transactive?</th>
    </tr>
    <tr>
        <td> (Top level) </td>
        <td> (Low level) </td>
        <td> </td>
    </tr>
    <tr>
        <td>Requests</td>
        <td>Feedback Request</td>
        <td>Yes</td>
    </tr>
    <tr>
        <td></td>
        <td>Justification Request</td>
        <td>Yes</td>
    </tr>
    <hr/>
    <tr>
        <td>Elaborates</td>
        <td>Extension</td>
        <td>Yes</td>
    </tr>
    <tr>
        <td></td>
        <td>Juxtaposition</td>
        <td>Yes</td>
    </tr>
    <tr>
        <td></td>
        <td>Clarification</td>
        <td>Yes</td>
    </tr>
    <tr>
        <td></td>
        <td>Refinement</td>
        <td>Yes</td>
    </tr>
    <tr>
        <td></td>
        <td>Reasoning Critique</td>
        <td>Yes</td>
    </tr>
    <hr/>
    <tr>
        <td></td>
        <td></td>
        <td></td>
    </tr>
    <tr>
        <td></td>
        <td></td>
        <td></td>
    </tr>
    <tr>
        <td></td>
        <td></td>
        <td></td>
    </tr>
</table>


## File Format
Annotaded data grouped by course and forums under each course is provided in an encrypted zip file at https://github.com/WING-NUS/NUS-MOOC-Transacts-Corpus/blob/master/data/nus-mooc-transacts-corpus-pswd-protected.zip
For example, a file annotated threads from 'Lecture' forum of course warhol-001 is named as: warhol-001.lecture.1.csv

Directory Structure:<br/>
--|__ Task1-Marking_Task <br/>
  |__ Task2-Categorisation_Task_low_lvl <br/>
  |__ Task2-Categorisation_Task_top_lvl <br/> 

Each file 'Task1-Marking_Task' consists of following headers:
"HITId","HITTypeId","Title","Description","Keywords","Reward","CreationTime","MaxAssignments","RequesterAnnotation","AssignmentDurationInSeconds","AutoApprovalDelayInSeconds","Expiration","NumberOfSimilarHITs","LifetimeInSeconds","AssignmentId","WorkerId","AssignmentStatus","AcceptTime","SubmitTime","AutoApprovalTime","ApprovalTime","RejectionTime","RequesterFeedback","WorkTimeInSeconds","LifetimeApprovalRate","Last30DaysApprovalRate","Last7DaysApprovalRate","Input.threadtype","Input.threadtitle","Input.posts","Input.inst_post", Answer.1, Answer.2,....Answer.n (where n is the total number of posts in the thread.)


## ACKNOWLEDGEMENTS
The corpus creation was partially funded by National University of Singapore (NUS) - Office of the Provost through Learning Innovation Fund - Technology (LIF-T) grant # C-252-000-123-001
