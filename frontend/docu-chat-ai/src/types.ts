export interface IFile {
  documentId: string;
  key: string; // "12345-abc/resume.pdf"
  size: number;
  lastModified: string;
  resource: string;
}
