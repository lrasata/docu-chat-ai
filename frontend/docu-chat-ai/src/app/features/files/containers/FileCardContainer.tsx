import { Box, Typography, Checkbox, Chip, Tooltip } from "@mui/material";
import PictureAsPdfIcon from "@mui/icons-material/PictureAsPdf";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import RadioButtonUncheckedIcon from "@mui/icons-material/RadioButtonUnchecked";
import { useState } from "react";
import type { IFile } from "../../../shared/types/types.ts";

interface FileCardContainerProps {
  files: IFile[];
  onSelectionChange?: (selectedIds: string[]) => void;
}

const formatBytes = (bytes: number): string => {
  if (!bytes) return "—";
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
};

const formatDate = (dateStr: string | undefined): string => {
  if (!dateStr) return "—";
  return new Date(dateStr).toLocaleDateString(undefined, {
    day: "2-digit",
    month: "short",
    year: "numeric",
  });
};

const truncateName = (name: string, max = 28): string =>
  name.length > max ? name.slice(0, max - 1) + "…" : name;

const FileCardContainer = ({
  files,
  onSelectionChange,
}: FileCardContainerProps) => {
  const [selected, setSelected] = useState<Set<string>>(new Set());

  const toggle = (id: string) => {
    setSelected((prev) => {
      const next = new Set(prev);
      next.has(id) ? next.delete(id) : next.add(id);
      onSelectionChange?.([...next]);
      return next;
    });
  };

  const toggleAll = () => {
    if (selected.size === files.length) {
      setSelected(new Set());
      onSelectionChange?.([]);
    } else {
      const all = new Set(files.map((f) => f.documentId));
      setSelected(all);
      onSelectionChange?.([...all]);
    }
  };

  if (!files || files.length === 0) {
    return (
      <Box
        sx={{
          mt: 3,
          py: 5,
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          gap: 1,
          border: "1px dashed",
          borderColor: "divider",
          borderRadius: 2,
        }}
      >
        <PictureAsPdfIcon sx={{ fontSize: 32, color: "text.disabled" }} />
        <Typography variant="body2" color="text.disabled">
          No files uploaded yet
        </Typography>
      </Box>
    );
  }

  return (
    <Box sx={{ mt: 3 }}>
      {/* Header row */}
      <Box
        sx={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          mb: 1.5,
          px: 0.5,
        }}
      >
        <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
          <Typography variant="body2" color="text.secondary">
            Files
          </Typography>
          <Chip
            label={files.length}
            size="small"
            sx={{ height: 18, fontSize: "0.65rem" }}
          />
          {selected.size > 0 && (
            <Chip
              label={`${selected.size} selected`}
              size="small"
              color="primary"
              variant="outlined"
              sx={{ height: 18, fontSize: "0.65rem" }}
            />
          )}
        </Box>
        <Typography
          variant="caption"
          color="primary"
          onClick={toggleAll}
          sx={{
            cursor: "pointer",
            userSelect: "none",
            "&:hover": { textDecoration: "underline" },
          }}
        >
          {selected.size === files.length ? "Deselect all" : "Select all"}
        </Typography>
      </Box>

      {/* Cards grid */}
      <Box
        sx={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fill, minmax(200px, 1fr))",
          gap: 1.5,
        }}
      >
        {files.map((file) => {
          const isSelected = selected.has(file.documentId);
          return (
            <Box
              key={file.documentId}
              onClick={() => toggle(file.documentId)}
              sx={{
                position: "relative",
                border: "1.5px solid",
                borderColor: isSelected ? "primary.main" : "divider",
                borderRadius: 2,
                p: 1.5,
                cursor: "pointer",
                bgcolor: isSelected ? "primary.50" : "background.paper",
                transition: "all 0.15s ease",
                "&:hover": {
                  borderColor: "primary.main",
                  bgcolor: isSelected ? "primary.50" : "action.hover",
                },
                // Subtle selected background that works light/dark
                ...(isSelected && {
                  bgcolor: (theme) =>
                    theme.palette.mode === "dark"
                      ? "rgba(25, 118, 210, 0.08)"
                      : "rgba(25, 118, 210, 0.04)",
                }),
              }}
            >
              {/* Checkbox */}
              <Checkbox
                checked={isSelected}
                size="small"
                icon={<RadioButtonUncheckedIcon sx={{ fontSize: 18 }} />}
                checkedIcon={<CheckCircleIcon sx={{ fontSize: 18 }} />}
                sx={{
                  position: "absolute",
                  top: 6,
                  right: 6,
                  p: 0,
                  color: "text.disabled",
                  "&.Mui-checked": { color: "primary.main" },
                }}
                onClick={(e) => e.stopPropagation()}
                onChange={() => toggle(file.documentId)}
              />

              {/* PDF icon */}
              <Box
                sx={{
                  width: 40,
                  height: 40,
                  borderRadius: 1.5,
                  bgcolor: isSelected ? "primary.main" : "action.selected",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  mb: 1.5,
                  transition: "background 0.15s",
                }}
              >
                <PictureAsPdfIcon
                  sx={{
                    fontSize: 22,
                    color: isSelected
                      ? "primary.contrastText"
                      : "text.secondary",
                  }}
                />
              </Box>

              {/* File name */}
              <Tooltip title={file.key} placement="top" enterDelay={600}>
                <Typography
                  variant="body2"
                  fontWeight={500}
                  sx={{
                    lineHeight: 1.3,
                    mb: 1,
                    wordBreak: "break-word",
                    fontSize: "0.8rem",
                  }}
                >
                  {truncateName(file.key)}
                </Typography>
              </Tooltip>

              {/* Meta row */}
              <Box
                sx={{
                  display: "flex",
                  flexDirection: "column",
                  gap: 0.25,
                }}
              >
                <Typography
                  variant="caption"
                  color="text.secondary"
                  sx={{ fontSize: "0.7rem" }}
                >
                  {formatBytes(file.size)}
                </Typography>
                <Typography
                  variant="caption"
                  color="text.disabled"
                  sx={{ fontSize: "0.7rem" }}
                >
                  {formatDate(file.lastModified)}
                </Typography>
              </Box>
            </Box>
          );
        })}
      </Box>
    </Box>
  );
};

export default FileCardContainer;
