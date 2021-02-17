# NUS MOOC Transacts Corpus
This is an annotated corpus of discussion forum threads from Massive Open Online Courses (MOOCs). The annotations are grounded on a pedagogy based discourse framework that adapts from and codifies 'transactivity' as proposed by Berkowitz and Gibbs, 1983. This is a simplified adadpation of their pedagogical/psychology based coding scheme, for instructor posts and replies in MOOC discussion forums.

We also propose inter-annotator agreement measures for a piecewise crowdsourcing annotation task to annotate the forum discussions with our modified taxonomy of transactive interventions.

However, due to privacy concerns and copyright claimed by MOOC platforms such as Coursera.org, we have encrypted the data. We also reserve the rights for access, use and distribution of the data. 

All rights reserved.

For access and use, please fill out the academic research purpose license form at http://bit.ly/wing-nus-mooc-transacts-corpus-request-form. 
We hold personal liability for the data to NUS and Coursera. We will review your request and get back to you within five (5) business days.

### Citation:

If you use the corpus for your research please cite:

```
@phdthesis{Chandrasekaranthesis2019,
    author = {MUTHU KUMAR CHANDRASEKARAN},
    school   = {National University of Singapore},
    title = {A DISCOURSE CENTRIC FRAMEWORK FOR FACILITATING INSTRUCTOR INTERVENTION IN MOOC DISCUSSION FORUMS},
    year = {2019},
}
```

## Data
Repository contains serially annotated data for 3 natural language processing tasks on MOOC discussion threads. <br/>
Given a complete thread of posts from a MOOC forum up until an instructor intervenes (writes a post / comment), we ask annotators / an NLP system:<br/>
* Task 1 (Marking Task): to link the instructor post to the earlier student post(s) to which it acts as a reply or as a comment.
* Task 2 (Categorization Task): to categorize the pair thus identified with the most suitable type(s) from our predefined inventory of discourse types in Table.
Task 2 is subdivided into two where first we ask to classify the post pair with a Top level category (see table below) and then into a subcategory (see table below) beneath the chosen top level category.

### Annotation Categories

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
    <tr>
        <td>Resolves</td>
        <td>Completion</td>
        <td>Yes</td>
    </tr>
    <tr>
        <td></td>
        <td>Paraphrase</td>
        <td>Yes</td>
    </tr>
    <tr>
        <td></td>
        <td>Integration & Summing up</td>
        <td>Yes</td>
    </tr>
    <tr>
        <td></td>
        <td>Agreement</td>
        <td>Yes</td>
    </tr>
    <tr>
        <td></td>
        <td>Disagreement</td>
        <td>Yes</td>
    </tr>
    <tr>
        <td></td>
        <td>Generic Answer</td>
        <td>No</td>
    </tr>
    <tr>
        <td></td>
        <td>Appreciation</td>
        <td>No</td>
    </tr>
    <tr>
        <td>Social</td>
        <td>Other logistics</td>
        <td>No</td>
    </tr>
    <tr>
        <td></td>
        <td>Social</td>
        <td>No</td>
    </tr>
</table>


### File Format
Annotaded data grouped by course and forums under each course is provided in an encrypted zip file at https://github.com/WING-NUS/NUS-MOOC-Transacts-Corpus/blob/master/data/nus-mooc-transacts-corpus-pswd-protected.zip
For example, a file annotated threads from 'Lecture' forum of course warhol-001 is named as: warhol-001.lecture.1.csv

Directory Structure:<br/>
<pre><code>
--|__ Task1-Marking_Task <br/>
  |__ Task2-Categorisation_Task_low_lvl <br/>
  |__ Task2-Categorisation_Task_top_lvl <br/> 
</code> </pre>

Each file 'Task1-Marking_Task' consists of following headers:<br/>
<pre><code>
"HITId", "HITTypeId", "Title", "Description", "Keywords", "Reward", <br/>
"CreationTime", "MaxAssignments", "RequesterAnnotation", "AssignmentDurationInSeconds", <br/> 
"AutoApprovalDelayInSeconds", "Expiration", "NumberOfSimilarHITs", "LifetimeInSeconds", <br/>
"AssignmentId", "WorkerId", "AssignmentStatus", "AcceptTime", "SubmitTime", <br/>
"AutoApprovalTime", "ApprovalTime", "RejectionTime", "RequesterFeedback", <br/> 
"WorkTimeInSeconds", "LifetimeApprovalRate", "Last30DaysApprovalRate", "Last7DaysApprovalRate", <br/>
"Input.threadtype", "Input.threadtitle", "Input.posts", "Input.inst_post", <br/>
"Answer.1", "Answer.2", ... "Answer.n" (where n is the total number of posts in the thread.)
</code> </pre>
Each Answer.x is either Marked or Unmarked by the annotator

Each file 'Task2-Categorisation_Task_top_lvl' consists of following headers:<br/>
<pre><code>
"HITId", "HITTypeId", "Title", "Description", "Keywords", "Reward", <br/>
"CreationTime", "MaxAssignments", "RequesterAnnotation", "AssignmentDurationInSeconds", <br/> 
"AutoApprovalDelayInSeconds", "Expiration", "NumberOfSimilarHITs", "LifetimeInSeconds", <br/>
"AssignmentId", "WorkerId", "AssignmentStatus", "AcceptTime", "SubmitTime", <br/>
"AutoApprovalTime", "ApprovalTime", "RejectionTime", "RequesterFeedback", <br/> 
"WorkTimeInSeconds", "LifetimeApprovalRate", "Last30DaysApprovalRate", "Last7DaysApprovalRate", <br/>
"Input.threadtype", "Input.threadtitle", "Input.posts", "Input.inst_post", <br/>
"Answer.1_discourse_type", ..., "Answer.X_discourse_type", "Answer.noreply", "Approve", "Reject"
</code> </pre>
Each Answer.x is is a top level discourse category (see table above) for each Marked post from the previous task output

File format for Task2-Categorisation_Task_low_lvl is similar except the discourse categories are chosen from low level discourse category (see table above)

In all three files formats columns: "Input.posts", "Input.inst_post" are in html format. When processing your input we strongly recommend you to drop the columns to easily visualize the data and the annotation. 

The following columns are an artefact of the MTurk system and are unlikely to be of use for model development. We recommend you to drop them as well before processing the annotations for model development. The columns are:

<pre><code>
"HITTypeId", "Title", "Description", "Keywords", "Reward", <br/>
"CreationTime", "MaxAssignments", "RequesterAnnotation", "AssignmentDurationInSeconds", <br/> 
"AutoApprovalDelayInSeconds", "Expiration", "NumberOfSimilarHITs", "LifetimeInSeconds", <br/>
"AssignmentId", "AssignmentStatus", "AcceptTime", "SubmitTime", <br/>
"AutoApprovalTime", "ApprovalTime", "RejectionTime", "RequesterFeedback", <br/> 
"WorkTimeInSeconds", "LifetimeApprovalRate", "Last30DaysApprovalRate", "Last7DaysApprovalRate", <br/>
</code> </pre>

#### Annotators
All annotators were crowdworkers recruited from Amazon MTruk platform. Each thread is annotated by 7 workers. You can aggregate the categories and calculate Inter Annotator Agreements using the scripts https://github.com/cmkumar87/NUS-MOOC-Transacts-Corpus/blob/master/scripts/analysis/fleiss_kappa_per_post.py and https://github.com/cmkumar87/NUS-MOOC-Transacts-Corpus/blob/master/scripts/analysis/fleiss_kappa_per_thread.py.

If you have questions / issues with preprocessing and/or IAA please raise a github issue.

### ACKNOWLEDGEMENTS
The corpus creation was partially funded by National University of Singapore (NUS) - Office of the Provost through Learning Innovation Fund - Technology (LIF-T) grant # C-252-000-123-001
